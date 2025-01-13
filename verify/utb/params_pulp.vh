`define TB_TOP EF_TCC32_apb_pulp_pwm_tb
`define DUT_PATH `TB_TOP.MUV

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

localparam[15:0] TIMER_REG_ADDR         = TIMER_REG_IDX         * 4;
localparam[15:0] PERIOD_REG_ADDR        = PERIOD_REG_IDX        * 4;
localparam[15:0] COUNTER_REG_ADDR       = COUNTER_REG_IDX       * 4;
localparam[15:0] COUNTER_MATCH_REG_ADDR = COUNTER_MATCH_REG_IDX * 4;
localparam[15:0] CONTROL_REG_ADDR       = CONTROL_REG_IDX       * 4;
localparam[15:0] PWM_COMP_VAL_ADDR      = PWM_COMP_VAL_REG_IDX  * 4;
localparam[15:0] RIS_REG_ADDR           = RIS_REG_IDX           * 4;
localparam[15:0] IM_REG_ADDR            = IM_REG_IDX            * 4;
localparam[15:0] MIS_REG_ADDR           = MIS_REG_IDX           * 4;

localparam  CTRL_EN                     = 1,
            CTRL_TMR_EN                 = 2,
            CTRL_PWM_EN                 = 4,
            CTRL_CP_EN                  = 8,
            CTRL_COUNT_UP               = 32'h10000,
            CTRL_MODE_ONESHOT           = 32'h20000,
            CTRL_CLKSRC_EXT             = 32'h900,
            CTRL_CLKSRC_DIV1            = 32'h800,
            CTRL_CLKSRC_DIV2            = 32'h000,
            CTRL_CLKSRC_DIV4            = 32'h100,
            CTRL_CLKSRC_DIV256          = 32'h70,
            CTRL_CPEVENT_PE             = 32'h1_00_0000,
            CTRL_CPEVENT_NE             = 32'h2_00_0000,
            CTRL_CPEVENT_BE             = 32'h3_00_0000;
                
localparam  INT_TO_FLAG                 = 1,
            INT_MATCH_FLAG              = 4,
            INT_CP_FLAG                 = 2;