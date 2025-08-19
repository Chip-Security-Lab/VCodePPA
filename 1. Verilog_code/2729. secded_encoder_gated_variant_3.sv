//SystemVerilog
module secded_encoder_gated(
    input clk, rst,
    input valid,
    output ready,
    input [3:0] data,
    output reg [7:0] code
);

    reg busy;
    wire processing;
    reg [6:0] hamming_code;
    
    assign processing = valid && !busy;
    assign ready = !busy;

    // 状态控制逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            busy <= 1'b0;
        end else begin
            if (processing) begin
                busy <= 1'b1;
            end else if (busy) begin
                busy <= 1'b0;
            end
        end
    end

    // 汉明码计算逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hamming_code <= 7'b0;
        end else if (processing) begin
            hamming_code[0] <= data[0] ^ data[1] ^ data[3];
            hamming_code[1] <= data[0] ^ data[2] ^ data[3];
            hamming_code[2] <= data[0];
            hamming_code[3] <= data[1] ^ data[2] ^ data[3];
            hamming_code[4] <= data[1];
            hamming_code[5] <= data[2];
            hamming_code[6] <= data[3];
        end
    end

    // 输出编码逻辑
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            code <= 8'b0;
        end else if (processing) begin
            code <= {^(data[0] ^ data[1] ^ data[3]), 
                    data[0] ^ data[1] ^ data[3],
                    data[0] ^ data[2] ^ data[3],
                    data[0],
                    data[1] ^ data[2] ^ data[3],
                    data[1],
                    data[2],
                    data[3]};
        end
    end

endmodule