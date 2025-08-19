//SystemVerilog
module mult_karatsuba (
    input clk, start,
    input [7:0] multiplicand, multiplier,
    output reg [15:0] product,
    output reg done
);

    // Internal registers for Karatsuba algorithm
    reg [3:0] a_high, a_low, b_high, b_low;
    reg [7:0] z0, z1, z2;
    reg [3:0] state;
    reg [7:0] temp_sum_a, temp_sum_b;
    
    // State definitions
    localparam IDLE = 4'd0;
    localparam CALC_Z0 = 4'd1;
    localparam CALC_Z1 = 4'd2;
    localparam CALC_Z2 = 4'd3;
    localparam COMBINE = 4'd4;

    // State machine control
    always @(posedge clk) begin
        if(start) begin
            state <= IDLE;
            done <= 0;
        end else begin
            case(state)
                IDLE: state <= CALC_Z0;
                CALC_Z0: state <= CALC_Z1;
                CALC_Z1: state <= CALC_Z2;
                CALC_Z2: state <= COMBINE;
                COMBINE: begin
                    state <= IDLE;
                    done <= 1;
                end
            endcase
        end
    end

    // Input register loading
    always @(posedge clk) begin
        if(start) begin
            a_high <= multiplicand[7:4];
            a_low <= multiplicand[3:0];
            b_high <= multiplier[7:4];
            b_low <= multiplier[3:0];
        end
    end

    // Z0 calculation
    always @(posedge clk) begin
        if(state == CALC_Z0) begin
            z0 <= a_low * b_low;
            temp_sum_a <= a_high + a_low;
            temp_sum_b <= b_high + b_low;
        end
    end

    // Z1 calculation
    always @(posedge clk) begin
        if(state == CALC_Z1) begin
            z1 <= temp_sum_a * temp_sum_b;
        end
    end

    // Z2 calculation
    always @(posedge clk) begin
        if(state == CALC_Z2) begin
            z2 <= a_high * b_high;
        end
    end

    // Final product calculation
    always @(posedge clk) begin
        if(state == COMBINE) begin
            product <= (z2 << 8) + ((z1 - z2 - z0) << 4) + z0;
        end
    end

endmodule