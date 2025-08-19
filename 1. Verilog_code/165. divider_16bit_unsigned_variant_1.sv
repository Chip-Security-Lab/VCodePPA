//SystemVerilog
module divider_16bit_unsigned (
    input clk,
    input rst_n,
    input [15:0] a,
    input [15:0] b,
    output reg [15:0] quotient,
    output reg [15:0] remainder
);

    reg [15:0] dividend;
    reg [15:0] divisor;
    reg [15:0] temp_quotient;
    reg [15:0] temp_remainder;
    reg [4:0] count;
    reg state;
    
    // Buffer registers for high fanout signals
    reg [15:0] temp_remainder_buf;
    reg [4:0] count_buf;
    reg [15:0] d0_buf;
    reg [15:0] d1_buf;
    reg [15:0] d2_buf;
    reg [15:0] d3_buf;
    reg [15:0] d4_buf;
    reg [15:0] d5_buf;
    reg [15:0] d6_buf;
    reg [15:0] d7_buf;
    reg [15:0] d8_buf;
    reg [15:0] d9_buf;
    reg [15:0] d10_buf;
    reg [15:0] d11_buf;
    reg [15:0] d12_buf;
    reg [15:0] d13_buf;
    reg [15:0] d14_buf;
    reg [15:0] d15_buf;
    
    // Intermediate signals for load balancing
    reg [15:0] temp_remainder_next;
    reg [4:0] count_next;
    reg [15:0] temp_quotient_next;
    reg state_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dividend <= 16'd0;
            divisor <= 16'd0;
            temp_quotient <= 16'd0;
            temp_remainder <= 16'd0;
            count <= 5'd0;
            state <= 1'b0;
            quotient <= 16'd0;
            remainder <= 16'd0;
            
            // Reset buffer registers
            temp_remainder_buf <= 16'd0;
            count_buf <= 5'd0;
            d0_buf <= 16'd0;
            d1_buf <= 16'd0;
            d2_buf <= 16'd0;
            d3_buf <= 16'd0;
            d4_buf <= 16'd0;
            d5_buf <= 16'd0;
            d6_buf <= 16'd0;
            d7_buf <= 16'd0;
            d8_buf <= 16'd0;
            d9_buf <= 16'd0;
            d10_buf <= 16'd0;
            d11_buf <= 16'd0;
            d12_buf <= 16'd0;
            d13_buf <= 16'd0;
            d14_buf <= 16'd0;
            d15_buf <= 16'd0;
            
            temp_remainder_next <= 16'd0;
            count_next <= 5'd0;
            temp_quotient_next <= 16'd0;
            state_next <= 1'b0;
        end else begin
            // Update buffer registers
            temp_remainder_buf <= temp_remainder;
            count_buf <= count;
            
            // Distribute load for dividend bits
            d0_buf <= {temp_remainder[14:0], dividend[0]};
            d1_buf <= {temp_remainder[14:0], dividend[1]};
            d2_buf <= {temp_remainder[14:0], dividend[2]};
            d3_buf <= {temp_remainder[14:0], dividend[3]};
            d4_buf <= {temp_remainder[14:0], dividend[4]};
            d5_buf <= {temp_remainder[14:0], dividend[5]};
            d6_buf <= {temp_remainder[14:0], dividend[6]};
            d7_buf <= {temp_remainder[14:0], dividend[7]};
            d8_buf <= {temp_remainder[14:0], dividend[8]};
            d9_buf <= {temp_remainder[14:0], dividend[9]};
            d10_buf <= {temp_remainder[14:0], dividend[10]};
            d11_buf <= {temp_remainder[14:0], dividend[11]};
            d12_buf <= {temp_remainder[14:0], dividend[12]};
            d13_buf <= {temp_remainder[14:0], dividend[13]};
            d14_buf <= {temp_remainder[14:0], dividend[14]};
            d15_buf <= {temp_remainder[14:0], dividend[15]};
            
            // Calculate next values
            case (state)
                1'b0: begin
                    if (b != 16'd0) begin
                        dividend <= a;
                        divisor <= b;
                        temp_quotient_next <= 16'd0;
                        temp_remainder_next <= 16'd0;
                        count_next <= 5'd15;
                        state_next <= 1'b1;
                    end
                end
                1'b1: begin
                    if (count_buf > 5'd0) begin
                        // Use buffered values for calculations
                        case (count_buf)
                            5'd15: temp_remainder_next = d15_buf;
                            5'd14: temp_remainder_next = d14_buf;
                            5'd13: temp_remainder_next = d13_buf;
                            5'd12: temp_remainder_next = d12_buf;
                            5'd11: temp_remainder_next = d11_buf;
                            5'd10: temp_remainder_next = d10_buf;
                            5'd9: temp_remainder_next = d9_buf;
                            5'd8: temp_remainder_next = d8_buf;
                            5'd7: temp_remainder_next = d7_buf;
                            5'd6: temp_remainder_next = d6_buf;
                            5'd5: temp_remainder_next = d5_buf;
                            5'd4: temp_remainder_next = d4_buf;
                            5'd3: temp_remainder_next = d3_buf;
                            5'd2: temp_remainder_next = d2_buf;
                            5'd1: temp_remainder_next = d1_buf;
                            default: temp_remainder_next = d0_buf;
                        endcase
                        
                        if (temp_remainder_next >= divisor) begin
                            temp_remainder_next = temp_remainder_next - divisor;
                            temp_quotient_next[count_buf] = 1'b1;
                        end
                        
                        count_next = count_buf - 5'd1;
                    end else begin
                        quotient <= temp_quotient;
                        remainder <= temp_remainder;
                        state_next <= 1'b0;
                    end
                end
            endcase
            
            // Update main registers with next values
            temp_remainder <= temp_remainder_next;
            count <= count_next;
            temp_quotient <= temp_quotient_next;
            state <= state_next;
        end
    end

endmodule