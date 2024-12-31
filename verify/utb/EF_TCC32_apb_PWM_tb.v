`timescale 1ns/1ps

module EF_TCC32_wb_tb;

    `include "params.vh"
    `include "apb_tasks.vh"

    localparam CLK_PERIOD = 40;
    localparam TIMEOUT = 2_000_000_000;

    reg         ctr_in;

    reg  		PCLK;
	reg  		PRESETn;
	reg  [31:0]	PADDR;
	reg  		PWRITE;
	reg  		PSEL;
	reg  		PENABLE;
	reg  [31:0]	PWDATA;
	wire [31:0]	PRDATA;
	wire 		PREADY;
	wire 		irq;
    wire        ext_clk = ctr_in;
    wire        pwm_out;

    // Для проверки ШИМ
    // Подсчет импульсов ШИМ
    reg  [31:0] pwm_pulse_count;

    EF_TCC32_apb MUV (
	    .ext_clk(ext_clk),
	    .PCLK(PCLK),
	    .PRESETn(PRESETn),
	    .PADDR(PADDR),
	    .PWRITE(PWRITE),
	    .PSEL(PSEL),
	    .PENABLE(PENABLE),
	    .PWDATA(PWDATA),
	    .PRDATA(PRDATA),
	    .PREADY(PREADY),
	    .irq(irq),
        .gpio_pwm(pwm_out)
    );

    // Dump the signals
    initial begin
        $dumpfile("EF_TCC32_PWM.vcd");
        $dumpvars(0, MUV);
    end

    // Stop the simulation after 1ms (Tiemout)
    initial begin
        #TIMEOUT;
        $display("Failed: Timeout");
        $finish; 
    end

    // clock and rest generator
    event power_on, reset_done;
    initial begin
        PCLK <= 1'bx;
        PRESETn <= 1'bx;
        // Power ON
        #25;
        -> power_on;
        PSEL <= 0;
        PENABLE <= 0;
    end

    always #(CLK_PERIOD/2) PCLK <= ~PCLK;

    initial begin
        @(power_on);
        PRESETn <= 1'b0;
        PCLK <= 1'b0;
        #999;
        @(posedge PCLK);
        PRESETn <= 1'b1;
        -> reset_done;
    end

    // External Events
    event extern_clk_start;
    initial begin
        ctr_in = 0;
        @(extern_clk_start);
        repeat(50)
            #(CLK_PERIOD*17.3/2) ctr_in = !ctr_in;
    end


    // Test Cases
    reg [31:0] data_out;
    // Test case 1
    // Timer time-out, one shot
    event test1_done, test2_done, test3_done, test4_done, testPWM_done;
    initial begin
        @(reset_done);
        // Period = 20
        apb_w_wr(PERIOD_REG_ADDR, 32'd20);
        // Clear all flags before enabling the Timer
        apb_w_wr(ICR_REG_ADDR, INT_TO_FLAG|INT_MATCH_FLAG|INT_CP_FLAG);
        // Down Counter, One Shot, Timer is Enabled and IP is enabled
        apb_w_wr(CONTROL_REG_ADDR, CTRL_EN|CTRL_TMR_EN|CTRL_MODE_ONESHOT);
        tmr_wait_to();
        $display("Test 1: Passed");
        #1000;
        -> test1_done;
    end
    
    // Test 2
    // Timer time-out, periodic
    initial begin
        @(test1_done);
        // Disable the timer before reconfiguring it.
        apb_w_wr(CONTROL_REG_ADDR, 32'h0);
        // Period = 20
        apb_w_wr(PERIOD_REG_ADDR, 32'd20);
        // Clear all flags before enabling the Timer
        apb_w_wr(ICR_REG_ADDR, 32'h7);
        // Down Counter, Periodic, Timer is Enabled and IP is enabled
        apb_w_wr(CONTROL_REG_ADDR, 32'h0000_0003);
        tmr_wait_to();
        tmr_wait_to();
        tmr_wait_to();
        $display("Test 2: Passed");
        #1000;
        -> test2_done;
    end

    // Test 3
    // Timer time-out IRQ, periodic
    initial begin
        @(test2_done);
        // Disable the timer before reconfiguring it.
        apb_w_wr(CONTROL_REG_ADDR, 32'h0);
        // Period = 20
        apb_w_wr(PERIOD_REG_ADDR, 32'd20);
        // Clear all flags before enabling the Timer (write to ICR)
        apb_w_wr(ICR_REG_ADDR, 32'h7);
        // Enable TO IRQ by writing to the IM Register
        apb_w_wr(IM_REG_ADDR, 32'h1);
        // Down Counter, Periodic, Timer is Enabled and IP is enabled
        apb_w_wr(CONTROL_REG_ADDR, 32'h0000_0003);
        // Wait for the irq to fire
        @(posedge irq);
        // Clear all the flags
        apb_w_wr(ICR_REG_ADDR, 32'h7);
        $display("Test 3: Passed");
        #1000;
        -> test3_done;
    end

    
    // Test 4
    // External Events Capture
    initial begin
        @(test3_done);
        -> extern_clk_start;
        // Disable the timer before reconfiguring it.
        apb_w_wr(CONTROL_REG_ADDR, 32'h0);
        // Clear all flags before enabling the Timer (write to ICR)
        apb_w_wr(ICR_REG_ADDR, 32'h7);
        // Enable Capture IRQ
        apb_w_wr(IM_REG_ADDR, 32'h2);
        // Up counting, 
        apb_w_wr(CONTROL_REG_ADDR, CTRL_EN|CTRL_TMR_EN|CTRL_CP_EN|CTRL_COUNT_UP|CTRL_CPEVENT_PE);
        // Wait for the irq to fire
        @(posedge irq);
        // Check the irq source
        apb_w_rd(MIS_REG_ADDR, data_out);
        if(data_out & 2) 
            $display("Test 4: Passed");
        else begin
            $display("Test 4: Failed");
            $finish;
        end
        // Clear all the flags
        apb_w_wr(ICR_REG_ADDR, 32'h7);
        #1000;
        -> test4_done;
    end

    /*
    Количество импульсов 
    Общее количество импульсов за 10 секунд:

    Частота PWM = 1 / (Период в наносекундах) = 1 / (1024 * 40) = 1 / 40960 Гц ≈ 0.0000244140625 с (или 24.414 мс).
    Количество циклов за 10 секунд = 10 секунд / 24.414 мс ≈ 409.6 циклов.
    Общее количество импульсов = 409.6 циклов * 1024 импульса/цикл ≈ 419840 импульсов.
    Количество высоких импульсов:

    Высокие импульсы = 409.6 циклов * 512 высоких импульсов/цикл ≈ 209920 высоких импульсов.
    */

    // Подсчет импульсов pwm_out
    initial begin
        pwm_pulse_count = 0; // Инициализация счетчика
        @(test4_done); // Ждем завершения теста 4
        forever @(posedge pwm_out) begin
            pwm_pulse_count = pwm_pulse_count + 1; // Инкрементируем счетчик
        end
    end


    // Test PWM
    initial begin
        @(test4_done);
        // Disable the timer before reconfiguring it.
        apb_w_wr(CONTROL_REG_ADDR, 32'h0);
        // Period = 1024
        apb_w_wr(PERIOD_REG_ADDR, 32'h400);
        // Clear all flags before enabling the Timer
        apb_w_wr(ICR_REG_ADDR, INT_TO_FLAG|INT_MATCH_FLAG|INT_CP_FLAG);
        // LAOD PWM compare value
        // PWM cmp val = 512
        apb_w_wr(PWM_COMP_VAL_ADDR, 32'h200);
        $display("Current PWM pulses: %d", pwm_pulse_count);
        // Up counting, 
        apb_w_wr(CONTROL_REG_ADDR, CTRL_EN|CTRL_TMR_EN|CTRL_PWM_EN|CTRL_CP_EN|CTRL_COUNT_UP);

        repeat (2_000_000) @ (posedge PCLK);     // Задержка на 2 секунды
        $display("Current PWM pulses: %d", pwm_pulse_count);

        // Disable the timer
        apb_w_wr(CONTROL_REG_ADDR, 0);
        // Clear all the flags
        apb_w_wr(ICR_REG_ADDR, 32'h7);

        // Проверка количества импульсов ШИМ
        if (pwm_pulse_count != 41984) begin
            $display("Test PWM: Failed - Expected high pulses: 41984, Actual: %d", pwm_pulse_count);
        end else begin
            $display("Test PWM: Passed - High pulses: %d", pwm_pulse_count);
        end

        -> testPWM_done;
        #1000;
        $display("All tests have passed!");
        $finish;
    end


task tmr_wait_to;
    begin: task_body
        reg [31:0] ris;
        ris = 0;
        while(ris == 0) begin
            apb_w_rd(RIS_REG_ADDR, ris);
        end 
    end
endtask

endmodule