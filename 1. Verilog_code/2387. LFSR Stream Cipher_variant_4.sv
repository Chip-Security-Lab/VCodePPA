//SystemVerilog
//IEEE 1364-2005 Verilog
module lfsr_stream_cipher #(parameter LFSR_WIDTH = 16, DATA_WIDTH = 8) (
    input wire clk, arst_l,
    input wire seed_load, encrypt,
    input wire [LFSR_WIDTH-1:0] seed,
    input wire [DATA_WIDTH-1:0] data_i,
    output reg [DATA_WIDTH-1:0] data_o
);
    reg [LFSR_WIDTH-1:0] lfsr_reg;
    reg [DATA_WIDTH-1:0] mask_reg;
    
    // 预计算的反馈位置表
    localparam [3:0] FEEDBACK_TAPS = 4'b1101;
    
    // 优化的反馈计算
    wire feedback = ^(lfsr_reg & {{(LFSR_WIDTH-4){1'b0}}, FEEDBACK_TAPS});
    
    // LFSR更新逻辑
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) 
            lfsr_reg <= {LFSR_WIDTH{1'b1}};
        else if (seed_load) 
            lfsr_reg <= seed;
        else 
            lfsr_reg <= {feedback, lfsr_reg[LFSR_WIDTH-1:1]};
    end
    
    // 预计算掩码寄存器
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l)
            mask_reg <= {DATA_WIDTH{1'b0}};
        else
            mask_reg <= lfsr_reg[LFSR_WIDTH-1:LFSR_WIDTH-DATA_WIDTH];
    end
    
    // 优化的输出逻辑
    always @(posedge clk or negedge arst_l) begin
        if (~arst_l) 
            data_o <= {DATA_WIDTH{1'b0}};
        else if (encrypt) 
            data_o <= data_i ^ mask_reg;
        else
            data_o <= data_o;
    end
endmodule