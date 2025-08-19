//SystemVerilog
module start_delay_clk(
    input clk_i,
    input rst_i,
    input [7:0] delay,
    output reg clk_o
);
    reg [7:0] delay_counter;
    reg [3:0] div_counter;
    reg started;
    
    // Carry lookahead adder signals
    wire [7:0] delay_counter_next;
    wire [7:0] delay_counter_plus_1;
    wire [7:0] delay_counter_plus_1_carry;
    wire [7:0] delay_counter_plus_1_propagate;
    wire [7:0] delay_counter_plus_1_generate;
    
    // Generate and propagate signals for carry lookahead
    assign delay_counter_plus_1_generate = delay_counter & 8'hFF;
    assign delay_counter_plus_1_propagate = delay_counter ^ 8'hFF;
    
    // Carry lookahead logic
    assign delay_counter_plus_1_carry[0] = 1'b1;
    assign delay_counter_plus_1_carry[1] = delay_counter_plus_1_generate[0] | (delay_counter_plus_1_propagate[0] & delay_counter_plus_1_carry[0]);
    assign delay_counter_plus_1_carry[2] = delay_counter_plus_1_generate[1] | (delay_counter_plus_1_propagate[1] & delay_counter_plus_1_carry[1]);
    assign delay_counter_plus_1_carry[3] = delay_counter_plus_1_generate[2] | (delay_counter_plus_1_propagate[2] & delay_counter_plus_1_carry[2]);
    assign delay_counter_plus_1_carry[4] = delay_counter_plus_1_generate[3] | (delay_counter_plus_1_propagate[3] & delay_counter_plus_1_carry[3]);
    assign delay_counter_plus_1_carry[5] = delay_counter_plus_1_generate[4] | (delay_counter_plus_1_propagate[4] & delay_counter_plus_1_carry[4]);
    assign delay_counter_plus_1_carry[6] = delay_counter_plus_1_generate[5] | (delay_counter_plus_1_propagate[5] & delay_counter_plus_1_carry[5]);
    assign delay_counter_plus_1_carry[7] = delay_counter_plus_1_generate[6] | (delay_counter_plus_1_propagate[6] & delay_counter_plus_1_carry[6]);
    
    // Sum calculation
    assign delay_counter_plus_1 = delay_counter_plus_1_propagate ^ delay_counter_plus_1_carry;
    
    // Next value selection
    assign delay_counter_next = (!started && delay_counter >= delay) ? 8'd0 : delay_counter_plus_1;
    
    always @(posedge clk_i or posedge rst_i) begin
        if (rst_i) begin
            delay_counter <= 8'd0;
            div_counter <= 4'd0;
            clk_o <= 1'b0;
            started <= 1'b0;
        end else begin
            case ({started, (delay_counter >= delay)})
                2'b00: begin // Not started and not reached delay
                    delay_counter <= delay_counter_next;
                end
                2'b01: begin // Not started but reached delay
                    started <= 1'b1;
                    delay_counter <= 8'd0;
                end
                2'b10, 2'b11: begin // Started (regardless of delay_counter value)
                    case (div_counter)
                        4'd9: begin
                            div_counter <= 4'd0;
                            clk_o <= ~clk_o;
                        end
                        default: begin
                            div_counter <= div_counter + 4'd1;
                        end
                    endcase
                end
            endcase
        end
    end
endmodule