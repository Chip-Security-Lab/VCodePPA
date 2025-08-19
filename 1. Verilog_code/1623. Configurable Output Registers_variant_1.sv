//SystemVerilog
module config_reg_decoder #(
    parameter REGISTERED_OUTPUT = 1
)(
    input clk,
    input rst_n,
    input [1:0] addr,
    input valid_in,
    output reg valid_out,
    output reg [3:0] dec_out
);

    // Optimized decoding logic using case statement
    reg [3:0] dec_stage1;
    reg valid_stage1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_stage1 <= 4'b0;
            valid_stage1 <= 1'b0;
        end else begin
            case(addr)
                2'b00: dec_stage1 <= 4'b0001;
                2'b01: dec_stage1 <= 4'b0010;
                2'b10: dec_stage1 <= 4'b0100;
                2'b11: dec_stage1 <= 4'b1000;
                default: dec_stage1 <= 4'b0000;
            endcase
            valid_stage1 <= valid_in;
        end
    end

    // Optimized output stage with direct decoding when not registered
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_out <= 4'b0;
            valid_out <= 1'b0;
        end else begin
            if (REGISTERED_OUTPUT) begin
                dec_out <= dec_stage1;
            end else begin
                case(addr)
                    2'b00: dec_out <= 4'b0001;
                    2'b01: dec_out <= 4'b0010;
                    2'b10: dec_out <= 4'b0100;
                    2'b11: dec_out <= 4'b1000;
                    default: dec_out <= 4'b0000;
                endcase
            end
            valid_out <= valid_stage1;
        end
    end

endmodule