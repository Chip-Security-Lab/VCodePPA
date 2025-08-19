//SystemVerilog
module width_reducer #(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 8  // IN_WIDTH必须是OUT_WIDTH的整数倍
)(
    input wire clk,
    input wire reset,
    input wire in_valid,
    input wire [IN_WIDTH-1:0] data_in,
    output wire [OUT_WIDTH-1:0] data_out,
    output wire out_valid,
    output wire ready_for_input
);

    // 参数和局部参数定义
    localparam RATIO = IN_WIDTH / OUT_WIDTH;
    localparam CNT_WIDTH = $clog2(RATIO);

    // 状态机状态定义
    localparam IDLE = 1'b0;
    localparam ACTIVE = 1'b1;

    // ================== Stage 1: 输入采集 ==================
    reg [IN_WIDTH-1:0] buffer_stage1;
    reg [CNT_WIDTH-1:0] count_stage1;
    reg state_stage1;
    reg valid_stage1;
    wire accept_input_stage1;

    assign accept_input_stage1 = in_valid && (state_stage1 == IDLE);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            buffer_stage1 <= {IN_WIDTH{1'b0}};
            count_stage1 <= {CNT_WIDTH{1'b0}};
            state_stage1 <= IDLE;
            valid_stage1 <= 1'b0;
        end else begin
            if (accept_input_stage1) begin
                buffer_stage1 <= data_in;
                count_stage1 <= {CNT_WIDTH{1'b0}};
                state_stage1 <= ACTIVE;
                valid_stage1 <= 1'b1;
            end else if ((state_stage1 == ACTIVE) && (count_stage1 < RATIO-1)) begin
                buffer_stage1 <= buffer_stage1 >> OUT_WIDTH;
                count_stage1 <= count_stage1 + 1'b1;
                state_stage1 <= ACTIVE;
                valid_stage1 <= 1'b1;
            end else if ((state_stage1 == ACTIVE) && (count_stage1 == RATIO-1)) begin
                buffer_stage1 <= buffer_stage1 >> OUT_WIDTH;
                count_stage1 <= {CNT_WIDTH{1'b0}};
                state_stage1 <= IDLE;
                valid_stage1 <= 1'b0;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    // ================== Stage 2: 输出准备 ==================
    reg [OUT_WIDTH-1:0] data_out_stage2;
    reg valid_stage2;
    reg flush_stage2;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out_stage2 <= {OUT_WIDTH{1'b0}};
            valid_stage2 <= 1'b0;
            flush_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                data_out_stage2 <= buffer_stage1[OUT_WIDTH-1:0];
                valid_stage2 <= 1'b1;
                flush_stage2 <= 1'b0;
            end else if ((state_stage1 == ACTIVE) && (count_stage1 == RATIO-1)) begin
                // 最后一个输出周期，flush
                valid_stage2 <= 1'b0;
                flush_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
                flush_stage2 <= 1'b0;
            end
        end
    end

    // ================== Stage 3: 输出寄存器/接口 ==================
    reg [OUT_WIDTH-1:0] data_out_stage3;
    reg out_valid_stage3;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            data_out_stage3 <= {OUT_WIDTH{1'b0}};
            out_valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                data_out_stage3 <= data_out_stage2;
                out_valid_stage3 <= 1'b1;
            end else if (flush_stage2) begin
                data_out_stage3 <= {OUT_WIDTH{1'b0}};
                out_valid_stage3 <= 1'b0;
            end else begin
                out_valid_stage3 <= 1'b0;
            end
        end
    end

    // ================== 接口输出 ==================
    assign data_out = data_out_stage3;
    assign out_valid = out_valid_stage3;
    assign ready_for_input = (state_stage1 == IDLE);

endmodule