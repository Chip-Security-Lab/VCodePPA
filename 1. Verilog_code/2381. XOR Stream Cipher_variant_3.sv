//SystemVerilog
module xor_stream_cipher #(parameter KEY_WIDTH = 8, DATA_WIDTH = 16) (
    input wire clk, rst_n,
    input wire [KEY_WIDTH-1:0] key,
    input wire [DATA_WIDTH-1:0] data_in,
    input wire valid_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg valid_out
);
    reg [KEY_WIDTH-1:0] key_reg;
    reg [KEY_WIDTH-1:0] next_key_reg;
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg valid_in_reg;
    
    // 输入寄存器逻辑
    always @(posedge clk) begin
        case (rst_n)
            1'b0: begin
                data_in_reg <= {DATA_WIDTH{1'b0}};
                valid_in_reg <= 1'b0;
                key_reg <= {KEY_WIDTH{1'b0}};
            end
            1'b1: begin
                data_in_reg <= data_in;
                valid_in_reg <= valid_in;
                key_reg <= next_key_reg;
            end
        endcase
    end
    
    // 组合逻辑计算下一个key值
    always @(*) begin
        case ({rst_n, valid_in})
            2'b00, 2'b01: next_key_reg = {KEY_WIDTH{1'b0}};
            2'b10: next_key_reg = key_reg;
            2'b11: next_key_reg = key ^ {key_reg[0], key_reg[KEY_WIDTH-1:1]};
            default: next_key_reg = key_reg;
        endcase
    end
    
    // 输出逻辑
    always @(posedge clk) begin
        case ({rst_n, valid_in_reg})
            2'b00, 2'b01: begin
                data_out <= {DATA_WIDTH{1'b0}};
                valid_out <= 1'b0;
            end
            2'b10: begin
                data_out <= data_out;
                valid_out <= 1'b0;
            end
            2'b11: begin
                data_out <= data_in_reg ^ {DATA_WIDTH/KEY_WIDTH{key_reg}};
                valid_out <= 1'b1;
            end
            default: begin
                data_out <= data_out;
                valid_out <= 1'b0;
            end
        endcase
    end
endmodule