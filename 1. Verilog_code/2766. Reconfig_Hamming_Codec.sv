module Reconfig_Hamming_Codec(
    input clk,
    input [1:0] config_mode,
    input [31:0] data_in,
    output reg [31:0] data_out
);
    // 完成所有case项
    always @(posedge clk) begin
        case(config_mode)
            2'b00: begin // (7,4)码
                data_out[6:0] <= {data_in[3:0], ^data_in[3:0], data_in[3]^data_in[2], data_in[3]^data_in[1]};
                data_out[31:7] <= data_in[31:4];
            end
            2'b01: begin // (15,11)码
                data_out[14:0] <= {data_in[10:0], 
                                  ^data_in[10:0],
                                  data_in[10]^data_in[9]^data_in[6]^data_in[5]^data_in[3]^data_in[0],
                                  data_in[10]^data_in[8]^data_in[7]^data_in[5]^data_in[4]^data_in[1],
                                  data_in[9]^data_in[8]^data_in[7]^data_in[3]^data_in[2]^data_in[0]};
                data_out[31:15] <= data_in[31:11];
            end
            2'b10: begin // (31,26)码
                data_out[30:0] <= {data_in[25:0], 
                                  ^data_in[25:0],
                                  ^{data_in[25:20], data_in[15:10], data_in[5:0]},
                                  ^{data_in[25:16], data_in[10:1]},
                                  ^{data_in[25:21], data_in[15:11], data_in[5:1]},
                                  ^{data_in[20:16], data_in[10:6], data_in[0]}};
                data_out[31] <= data_in[31:26] != 0;
            end
            2'b11: begin // SECDED
                data_out[31:0] <= {data_in[30:0], ^data_in[30:0]};
            end
        endcase
    end
endmodule