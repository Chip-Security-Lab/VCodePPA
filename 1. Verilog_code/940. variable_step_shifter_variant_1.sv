//SystemVerilog
module variable_step_shifter (
    input clk,
    input rst_n,
    input [15:0] din,
    input [1:0] step_mode,  // 00:+1, 01:+2, 10:+4
    input req,              // Request signal (replacing valid)
    output reg ack,         // Acknowledge signal (replacing ready)
    output reg [15:0] dout
);
    // Internal signals
    reg [15:0] din_reg;
    reg [1:0] step_mode_reg;
    reg processing;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ack <= 1'b0;
            dout <= 16'b0;
            din_reg <= 16'b0;
            step_mode_reg <= 2'b0;
            processing <= 1'b0;
        end else begin
            if (req && !processing) begin
                // Capture input data when request is received
                din_reg <= din;
                step_mode_reg <= step_mode;
                processing <= 1'b1;
                ack <= 1'b0;
            end else if (processing) begin
                // Process the data
                processing <= 1'b0;
                ack <= 1'b1;
                // Perform the shift operation
                case (step_mode_reg)
                    2'b00: dout <= {din_reg[14:0], din_reg[15]};    // +1
                    2'b01: dout <= {din_reg[13:0], din_reg[15:14]}; // +2
                    2'b10: dout <= {din_reg[11:0], din_reg[15:12]}; // +4
                    default: dout <= din_reg;
                endcase
            end else if (ack && !req) begin
                // Reset acknowledge when request is deasserted
                ack <= 1'b0;
            end
        end
    end
endmodule