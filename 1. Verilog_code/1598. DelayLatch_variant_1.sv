//SystemVerilog
module DelayLatch #(parameter DW=8, DEPTH=3) (
    input clk, rst_n, en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output valid
);

// 流水线控制信号
reg [DEPTH:0] valid_chain;
wire [DEPTH:0] ready_chain;

// 流水线数据信号
wire [DW-1:0] stage_data [0:DEPTH];

// 实例化流水线级
generate
    genvar i;
    for(i=0; i<DEPTH; i=i+1) begin: STAGE
        PipelineStage #(
            .DW(DW)
        ) u_stage (
            .clk(clk),
            .rst_n(rst_n),
            .valid_in(valid_chain[i]),
            .ready_in(ready_chain[i+1]),
            .din(stage_data[i]),
            .valid_out(valid_chain[i+1]),
            .ready_out(ready_chain[i]),
            .dout(stage_data[i+1])
        );
    end
endgenerate

// 输入级
assign stage_data[0] = din;
assign valid_chain[0] = en;
assign ready_chain[DEPTH] = 1'b1;

// 输出级
assign dout = stage_data[DEPTH];
assign valid = valid_chain[DEPTH];

endmodule

module PipelineStage #(parameter DW=8) (
    input clk, rst_n,
    input valid_in, ready_in,
    input [DW-1:0] din,
    output reg valid_out,
    output ready_out,
    output reg [DW-1:0] dout
);

// 流水线寄存器
reg [DW-1:0] data_reg;
reg valid_reg;

// 握手控制
assign ready_out = ready_in || !valid_out;

// 流水线逻辑
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        valid_reg <= 1'b0;
        data_reg <= {DW{1'b0}};
    end
    else if(ready_out) begin
        valid_reg <= valid_in;
        data_reg <= din;
    end
end

// 输出逻辑
always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        valid_out <= 1'b0;
        dout <= {DW{1'b0}};
    end
    else if(ready_in) begin
        valid_out <= valid_reg;
        dout <= data_reg;
    end
end

endmodule