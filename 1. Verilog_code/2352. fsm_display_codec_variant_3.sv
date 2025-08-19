//SystemVerilog
module fsm_display_codec (
    input wire clk, rst_n,
    // Input interface
    input wire [23:0] pixel_in,
    input wire in_valid,
    output wire in_ready,
    // Output interface
    output reg [15:0] pixel_out,
    output reg out_valid,
    input wire out_ready
);
    // FSM states
    localparam IDLE = 2'b00;
    localparam PROCESS = 2'b01;
    localparam WAIT_OUTPUT = 2'b10;
    
    reg [1:0] state, next_state;
    reg [15:0] processed_data;
    
    // Signals for Karatsuba multiplier
    reg [11:0] a, b;
    wire [23:0] mult_result;
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Input ready when in IDLE state
    assign in_ready = (state == IDLE);
    
    // Next state logic with valid-ready handshaking
    always @(*) begin
        case (state)
            IDLE: next_state = (in_valid && in_ready) ? PROCESS : IDLE;
            PROCESS: next_state = WAIT_OUTPUT;
            WAIT_OUTPUT: next_state = (out_valid && out_ready) ? IDLE : WAIT_OUTPUT;
            default: next_state = IDLE;
        endcase
    end
    
    // Karatsuba multiplier instantiation
    karatsuba_multiplier #(
        .WIDTH(12)
    ) mult_inst (
        .a(a),
        .b(b),
        .result(mult_result)
    );
    
    // Data processing and output with handshaking
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pixel_out <= 16'h0000;
            out_valid <= 1'b0;
            processed_data <= 16'h0000;
            a <= 12'h000;
            b <= 12'h000;
        end else begin
            case (state)
                IDLE: begin
                    out_valid <= 1'b0;
                    if (in_valid && in_ready) begin
                        // Use upper 12 bits for a and lower 12 bits for b
                        a <= pixel_in[23:12];
                        b <= pixel_in[11:0];
                    end
                end
                PROCESS: begin
                    // Use Karatsuba multiplication result to generate output
                    processed_data <= {mult_result[23:19], mult_result[15:10], mult_result[7:3]};
                    pixel_out <= {mult_result[23:19], mult_result[15:10], mult_result[7:3]};
                    out_valid <= 1'b1;
                end
                WAIT_OUTPUT: begin
                    // Keep output valid until handshake occurs
                    if (out_valid && out_ready) begin
                        out_valid <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule

// Karatsuba multiplier module implementation
module karatsuba_multiplier #(
    parameter WIDTH = 12
) (
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    output wire [2*WIDTH-1:0] result
);
    localparam HALF_WIDTH = WIDTH / 2;
    
    // Split inputs into high and low parts
    wire [HALF_WIDTH-1:0] a_low, b_low;
    wire [HALF_WIDTH-1:0] a_high, b_high;
    
    assign a_low = a[HALF_WIDTH-1:0];
    assign a_high = a[WIDTH-1:HALF_WIDTH];
    assign b_low = b[HALF_WIDTH-1:0];
    assign b_high = b[WIDTH-1:HALF_WIDTH];
    
    // Karatsuba algorithm components
    wire [WIDTH-1:0] z0, z1, z2;
    wire [WIDTH:0] sum_a, sum_b;
    wire [WIDTH+1:0] z1_temp;
    
    // z0 = a_low * b_low
    assign z0 = a_low * b_low;
    
    // z2 = a_high * b_high
    assign z2 = a_high * b_high;
    
    // sum_a = a_high + a_low
    // sum_b = b_high + b_low
    assign sum_a = {1'b0, a_high} + {1'b0, a_low};
    assign sum_b = {1'b0, b_high} + {1'b0, b_low};
    
    // z1_temp = (a_high + a_low) * (b_high + b_low)
    assign z1_temp = sum_a * sum_b;
    
    // z1 = z1_temp - z2 - z0
    assign z1 = z1_temp[WIDTH-1:0] - z2 - z0;
    
    // Combine the results: result = z2 << WIDTH + z1 << HALF_WIDTH + z0
    assign result = {z2, {HALF_WIDTH{1'b0}}} + {{HALF_WIDTH{1'b0}}, z1, {HALF_WIDTH{1'b0}}} + {{WIDTH{1'b0}}, z0};
    
endmodule