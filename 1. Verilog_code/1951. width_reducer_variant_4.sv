//SystemVerilog
module width_reducer #(
    parameter IN_WIDTH = 32,
    parameter OUT_WIDTH = 8  // IN_WIDTH必须是OUT_WIDTH的整数倍
)(
    input  wire                    clk,
    input  wire                    reset,
    input  wire                    in_valid,
    input  wire [IN_WIDTH-1:0]     data_in,
    output wire [OUT_WIDTH-1:0]    data_out,
    output wire                    out_valid,
    output wire                    ready_for_input
);

    // 优化流水线参数
    localparam RATIO     = IN_WIDTH / OUT_WIDTH;
    localparam CNT_WIDTH = (RATIO > 1) ? $clog2(RATIO) : 1;

    // 输入寄存器
    reg [IN_WIDTH-1:0]   input_data_reg;
    reg                  input_valid_reg;

    // 输出流水线寄存器
    reg [IN_WIDTH-1:0]   output_data_reg;
    reg [CNT_WIDTH-1:0]  output_count_reg;
    reg                  processing_reg;
    reg                  out_valid_reg;

    // 优化入口控制信号
    assign ready_for_input = (~processing_reg) & (~input_valid_reg);

    // 优化Stage 0：输入捕获
    always @(posedge clk) begin
        if (reset) begin
            input_data_reg  <= {IN_WIDTH{1'b0}};
            input_valid_reg <= 1'b0;
        end else if (in_valid & ready_for_input) begin
            input_data_reg  <= data_in;
            input_valid_reg <= 1'b1;
        end else if (input_valid_reg & ready_for_input) begin
            input_valid_reg <= 1'b0;
        end
    end

    // 优化Stage 1：数据缩减流水线
    always @(posedge clk) begin
        if (reset) begin
            output_data_reg   <= {IN_WIDTH{1'b0}};
            output_count_reg  <= {CNT_WIDTH{1'b0}};
            processing_reg    <= 1'b0;
            out_valid_reg     <= 1'b0;
        end else begin
            if (input_valid_reg & ready_for_input) begin
                // 捕获新输入，初始化流水线
                output_data_reg   <= input_data_reg;
                output_count_reg  <= {CNT_WIDTH{1'b0}};
                processing_reg    <= 1'b1;
                out_valid_reg     <= 1'b1;
            end else if (processing_reg) begin
                // 优化比较链：用范围检查和计数器终止条件替代链式比较
                if (output_count_reg + 1 < RATIO) begin
                    output_data_reg   <= output_data_reg >> OUT_WIDTH;
                    output_count_reg  <= output_count_reg + 1'b1;
                    out_valid_reg     <= 1'b1;
                end else begin
                    processing_reg    <= 1'b0;
                    out_valid_reg     <= 1'b0;
                end
            end else begin
                out_valid_reg <= 1'b0;
            end
        end
    end

    // 输出信号
    assign data_out  = output_data_reg[OUT_WIDTH-1:0];
    assign out_valid = out_valid_reg;

endmodule