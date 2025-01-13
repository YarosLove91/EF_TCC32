/*
Copyright 2023 Efabless Corp.

Author: Mohamed Shalan (mshalan@aucegypt.edu)

This file is auto-generated by wrapper_gen.py on 2023-10-19

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

*/

`timescale          1ns/1ns
`default_nettype    none

module EF_TCC32_apb 
#(
    parameter int APB_ADDR_W = 32
)
(
    input  wire ext_clk  ,
    input  wire PCLK     ,
    input  wire PRESETn  ,
    output wire irq      ,
    output wire gpio_pwm , // PWM gpio output
    // bus slave connections - periph bus and eu_direct_link
    APB.Slave    apb_slave
);

    // regs map (multiply by 4 to get address)
    localparam TIMER_REG_IDX         = 0              ; // r/o
    localparam PERIOD_REG_IDX        = 1              ; // r/w
    localparam COUNTER_REG_IDX       = 2              ; // r/o
    localparam COUNTER_MATCH_REG_IDX = 3              ; // r/w
    localparam CONTROL_REG_IDX       = 4              ; // r/w
    localparam PWM_COMP_VAL_REG_IDX  = 5              ; // r/w
    localparam RIS_REG_IDX           = 960            ; // w1c | irq flags, not masked
    localparam IM_REG_IDX            = 961            ; // r/w | irq flags mask
    localparam MIS_REG_IDX           = 962            ; // r/o | irq flags, masked
    localparam REGS_QTY              = MIS_REG_IDX + 1;

    // apb regs params
    localparam int                    REGS_OFFSET = 4         ; // 32bit aligned addresses
    localparam int                    APB_DATA_W  = APB_ADDR_W;
    localparam logic [APB_ADDR_W-1:0] BASE_ADDR   = 'd0       ; // TODO: clarify what address


    // read only regs indexes set for apb regs module
    function bit [REGS_QTY-1:0] set_read_only_regs();
        bit [REGS_QTY-1:0] res;
        res = '0;
        res[TIMER_REG_IDX]      = 1;
        res[COUNTER_REG_IDX]    = 1;
        res[MIS_REG_IDX]        = 1;
        res[(RIS_REG_IDX - 1):(PWM_COMP_VAL_REG_IDX + 1)] = '1; // reserved regs
        return res;
    endfunction : set_read_only_regs

    // write '1' to clear regs indexes set for apb regs module
    function bit [REGS_QTY-1:0] set_write_to_clear_regs();
        bit [REGS_QTY-1:0] res;
        res = '0;
        res[RIS_REG_IDX] = 1;
        return res;
    endfunction : set_write_to_clear_regs

    localparam bit [REGS_QTY-1:0] READ_ONLY      = set_read_only_regs();
    localparam bit [REGS_QTY-1:0] WRITE_TO_CLEAR = set_write_to_clear_regs();

    // structs for registers bit mapping
    typedef struct packed {
        logic [5:0] reserved_3; // 31
        logic [1:0] cp_event;
        logic [5:0] reserved_2;
        logic       one_shot;
        logic       up;
        logic [3:0] reserved_1;
        logic [3:0] clk_src;
        logic [3:0] reserved_0;
        logic       cp_en;
        logic       pwm_en;
        logic       tmr_en;
        logic       en;         // 0
    } ctrl_reg_t;

    typedef struct packed {
        logic [28:0] reserved_0;
        logic [ 2:0] mis;
    } mis_reg_t;

    typedef struct packed {
        logic [28:0] reserved_0;
        logic [ 2:0] im;
    } im_reg_t;

    typedef struct packed {
        logic [28:0] reserved_0;
        logic        match_flag;
        logic        cp_flag;
        logic        to_flag;
    } ris_reg_t;

    // struct for all timer regs
    typedef struct {
        logic [31:0] timer;
        logic [31:0] period;
        logic [31:0] counter;
        logic [31:0] counter_match;
        ctrl_reg_t   control;
        logic [31:0] pwm_comp;
        ris_reg_t    ris_i;
        ris_reg_t    ris_o;
        im_reg_t     im;
        mis_reg_t    mis;
    } regs_t;


    // signals declarations
    logic  ctr_in;
    logic  tmr_clk;
    logic  tmr_rst;
    regs_t all_regs;
    logic [REGS_QTY - 1:0][APB_DATA_W - 1:0] reg_inputs;
    logic [REGS_QTY - 1:0][APB_DATA_W - 1:0] reg_outputs;


    // apb regs
    apb_regs_intf #(
        .NO_APB_REGS   (REGS_QTY      ),   // number of registers
        .APB_ADDR_WIDTH(APB_ADDR_W    ),   // address width of `paddr`
        .ADDR_OFFSET   (REGS_OFFSET   ),   // address offset in bytes
        .APB_DATA_WIDTH(APB_DATA_W    ),   // data width of the registers
        .REG_DATA_WIDTH(APB_DATA_W    ),
        .READ_ONLY     (READ_ONLY     ),
        .WRITE_TO_CLEAR(WRITE_TO_CLEAR)
    ) apb_regs (
        .pclk_i     (PCLK       ),
        .presetn_i  (PRESETn    ),
        .slv        (apb_slave  ),
        .base_addr_i(BASE_ADDR  ),   // base address of the registers
        .reg_init_i (reg_inputs ),   // values for the read only registers
        .reg_q_o    (reg_outputs)    // actual regs' values
    );

    always_comb begin : regs_handler
        // r/w or w1c
        all_regs.period         = reg_outputs[PERIOD_REG_IDX];
        all_regs.counter_match  = reg_outputs[COUNTER_MATCH_REG_IDX];
        all_regs.control        = reg_outputs[CONTROL_REG_IDX];
        all_regs.pwm_comp       = reg_outputs[PWM_COMP_VAL_REG_IDX];
        all_regs.ris_o          = reg_outputs[RIS_REG_IDX];
        all_regs.im             = reg_outputs[IM_REG_IDX];

        all_regs.ris_i.reserved_0 = '0;

        // r/o
        for (int i = 0; i < REGS_QTY; i++) begin
            reg_inputs[i] = '0;
        end
        reg_inputs[TIMER_REG_IDX]   = all_regs.timer;
        reg_inputs[COUNTER_REG_IDX] = all_regs.counter;
        reg_inputs[RIS_REG_IDX]     = all_regs.ris_i;
        reg_inputs[MIS_REG_IDX]     = all_regs.mis;
    end


    // timer
    assign ctr_in    = ext_clk;
    assign tmr_clk   = PCLK;
    assign tmr_rst   = ~PRESETn;

    EF_TCC32 timer (
        .clk        (tmr_clk                  ),
        .rst_n      (~tmr_rst                 ),
        .ctr_in     (ctr_in                   ),
        .pwm_out_pin(gpio_pwm                 ),   // PWM signal out for GPIO
        .pwm_cmp_in (all_regs.pwm_comp        ),   // PWM input compare value
        .period     (all_regs.period          ),
        .ctr_match  (all_regs.counter_match   ),
        .tmr        (all_regs.timer           ),
        .cp_count   (all_regs.counter         ),
        .clk_src    (all_regs.control.clk_src ),
        .to_flag    (all_regs.ris_i.to_flag   ),
        .match_flag (all_regs.ris_i.match_flag),
        .tmr_en     (all_regs.control.tmr_en  ),
        .pwm_en     (all_regs.control.pwm_en  ),   // PWM_enable
        .one_shot   (all_regs.control.one_shot),
        .up         (all_regs.control.up      ),
        .cp_en      (all_regs.control.cp_en   ),
        .cp_event   (all_regs.control.cp_event),
        .cp_flag    (all_regs.ris_i.cp_flag   ),
        .en         (all_regs.control.en      )
    );

    assign all_regs.mis     = {all_regs.ris_o.match_flag, all_regs.ris_o.cp_flag, all_regs.ris_o.to_flag} & all_regs.im.im;
    assign irq              = |all_regs.mis;

endmodule