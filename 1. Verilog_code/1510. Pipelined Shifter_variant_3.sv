//SystemVerilog
// IEEE 1364-2005 Verilog
module pipelined_shifter #(parameter STAGES = 2, WIDTH = 8) (
    input wire clk, rst_n,
    input wire [WIDTH-1:0] data_in,
    output wire [WIDTH-1:0] data_out
);
    // 优化流水线级数，保持参数化设计
    reg [WIDTH-1:0] pipe [0:STAGES-1];
    
    // 第一级流水线寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe[0] <= {WIDTH{1'b0}};
        end else begin
            pipe[0] <= data_in;
        end
    end
    
    // 生成其余的流水线寄存器
    genvar i;
    generate
        for (i = 1; i < STAGES; i = i + 1) begin : shift_stages
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) begin
                    pipe[i] <= {WIDTH{1'b0}};
                end else begin
                    pipe[i] <= pipe[i-1];
                end
            end
        end
    endgenerate
    
    // 输出赋值
    assign data_out = pipe[STAGES-1];
endmodule