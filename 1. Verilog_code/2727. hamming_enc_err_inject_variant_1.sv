//SystemVerilog
module hamming_enc_err_inject(
    input clk, rst,
    input [3:0] data,
    input inject_error,
    input [2:0] error_pos,
    output reg [6:0] encoded
);
    reg [6:0] normal_encoded;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            encoded <= 7'b0;
            normal_encoded <= 7'b0;
        end else begin
            normal_encoded[0] <= data[0] ^ data[1] ^ data[3];
            normal_encoded[1] <= data[0] ^ data[2] ^ data[3];
            normal_encoded[2] <= data[0];
            normal_encoded[3] <= data[1] ^ data[2] ^ data[3];
            normal_encoded[4] <= data[1];
            normal_encoded[5] <= data[2];
            normal_encoded[6] <= data[3];
            
            if (inject_error) begin
                encoded <= normal_encoded ^ (1 << error_pos);
            end else begin
                encoded <= normal_encoded;
            end
        end
    end
endmodule