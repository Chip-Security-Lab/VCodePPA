//SystemVerilog
///////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////
module touch_decoder (
    input wire        clk,         // System clock
    input wire        rst_n,       // Active low reset
    input wire [11:0] x_raw,       // Raw X coordinate input
    input wire [11:0] y_raw,       // Raw Y coordinate input
    output reg [10:0] x_pos,       // Processed X coordinate output
    output reg [10:0] y_pos        // Processed Y coordinate output
);

    // Internal pipeline registers for X path
    reg [11:0] x_raw_reg;
    reg [10:0] x_calibrated;
    
    // Internal pipeline registers for Y path
    reg [11:0] y_raw_reg;
    reg [10:0] y_scaled;
    
    // Carry-lookahead adder signals
    wire [10:0] x_shifted;
    wire [10:0] offset;
    wire [10:0] sum;
    wire [11:0] carry;
    
    // Generate and propagate signals
    wire [10:0] G, P;
    
    // Stage 1: Register inputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_raw_reg <= 12'h0;
            y_raw_reg <= 12'h0;
        end else begin
            x_raw_reg <= x_raw;
            y_raw_reg <= y_raw;
        end
    end
    
    // Carry-lookahead adder implementation
    assign x_shifted = x_raw_reg[11:1];
    assign offset = 11'd5;
    
    // Generate and propagate signals
    assign G = x_shifted & offset;  // Generate
    assign P = x_shifted | offset;  // Propagate
    
    // Carry calculation with lookahead
    assign carry[0] = 1'b0;
    assign carry[1] = G[0] | (P[0] & carry[0]);
    assign carry[2] = G[1] | (P[1] & carry[1]);
    assign carry[3] = G[2] | (P[2] & carry[2]);
    assign carry[4] = G[3] | (P[3] & carry[3]);
    assign carry[5] = G[4] | (P[4] & carry[4]);
    assign carry[6] = G[5] | (P[5] & carry[5]);
    assign carry[7] = G[6] | (P[6] & carry[6]);
    assign carry[8] = G[7] | (P[7] & carry[7]);
    assign carry[9] = G[8] | (P[8] & carry[8]);
    assign carry[10] = G[9] | (P[9] & carry[9]);
    assign carry[11] = G[10] | (P[10] & carry[10]);
    
    // Sum calculation
    assign sum = x_shifted ^ offset ^ carry[10:0];
    
    // Stage 2: Calculate calibrated/scaled values
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_calibrated <= 11'h0;
            y_scaled <= 11'h0;
        end else begin
            x_calibrated <= sum;                 // Using CLA result
            y_scaled <= y_raw_reg[11:1] >> 1;    // Scale down
        end
    end
    
    // Stage 3: Register outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            x_pos <= 11'h0;
            y_pos <= 11'h0;
        end else begin
            x_pos <= x_calibrated;
            y_pos <= y_scaled;
        end
    end

endmodule