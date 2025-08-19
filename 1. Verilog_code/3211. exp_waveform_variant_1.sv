//SystemVerilog
module exp_waveform(
    input clk,
    input rst,
    input req,           // Request signal (replacing 'enable')
    input [9:0] data_in, // Added input data
    output reg ack,      // Acknowledge signal (replacing 'ready')
    output reg [9:0] exp_out
);
    reg [3:0] count;
    reg processing;
    
    // Req-Ack handshake protocol implementation
    always @(posedge clk) begin
        if (rst) begin
            count <= 4'd0;
            exp_out <= 10'd0;
            ack <= 1'b0;
            processing <= 1'b0;
        end else begin
            // Default value
            ack <= 1'b0;
            
            if (req && !processing) begin
                // Start processing when request received and not already processing
                processing <= 1'b1;
                count <= 4'd0;
            end else if (processing) begin
                // Continue processing sequence
                count <= count + 4'd1;
                
                // Optimized exponential waveform generation using case statement
                case (count)
                    4'd0:  exp_out <= 10'd1;
                    4'd1:  exp_out <= 10'd2;
                    4'd2:  exp_out <= 10'd4;
                    4'd3:  exp_out <= 10'd8;
                    4'd4:  exp_out <= 10'd16;
                    4'd5:  exp_out <= 10'd32;
                    4'd6:  exp_out <= 10'd64;
                    4'd7:  exp_out <= 10'd128;
                    4'd8:  exp_out <= 10'd256;
                    4'd9:  exp_out <= 10'd512;
                    4'd10: exp_out <= 10'd1023;
                    4'd11: exp_out <= 10'd512;
                    4'd12: exp_out <= 10'd256;
                    4'd13: exp_out <= 10'd128;
                    4'd14: exp_out <= 10'd64;
                    4'd15: begin
                        exp_out <= 10'd32;
                        ack <= 1'b1;      // Assert acknowledgment when complete
                        processing <= 1'b0; // Reset processing state
                    end
                    default: exp_out <= 10'd0;
                endcase
            end
        end
    end
endmodule