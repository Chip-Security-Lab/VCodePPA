//SystemVerilog
// Top-level fault-tolerant arbiter module
module FaultTolerantArbiter (
    input clk, 
    input rst,
    input [3:0] req,
    output [3:0] grant
);
    // Internal signals
    wire [3:0] grant_a, grant_b;
    wire valid_a, valid_b;
    
    // Instantiate primary arbiter
    ArbiterPrimary primary_arb (
        .clk(clk),
        .rst(rst),
        .req(req),
        .grant(grant_a),
        .valid(valid_a)
    );
    
    // Instantiate backup arbiter
    ArbiterBackup backup_arb (
        .clk(clk),
        .rst(rst),
        .req(req),
        .grant(grant_b),
        .valid(valid_b)
    );
    
    // Fault detection and output selection
    FaultDetector fault_detector (
        .grant_a(grant_a),
        .grant_b(grant_b),
        .valid_a(valid_a),
        .valid_b(valid_b),
        .grant(grant)
    );
endmodule

// Primary arbiter implementation with priority encoding
module ArbiterPrimary (
    input clk,
    input rst,
    input [3:0] req,
    output reg [3:0] grant,
    output reg valid
);
    // Priority encoder implementation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 4'b0000;
            valid <= 1'b0;
        end
        else begin
            grant <= 4'b0000;
            valid <= 1'b0;
            
            // Priority encoding logic
            if (req[0]) begin
                grant[0] <= 1'b1;
                valid <= 1'b1;
            end
            else if (req[1]) begin
                grant[1] <= 1'b1;
                valid <= 1'b1;
            end
            else if (req[2]) begin
                grant[2] <= 1'b1;
                valid <= 1'b1;
            end
            else if (req[3]) begin
                grant[3] <= 1'b1;
                valid <= 1'b1;
            end
        end
    end
endmodule

// Backup arbiter with different priority scheme
module ArbiterBackup (
    input clk,
    input rst,
    input [3:0] req,
    output reg [3:0] grant,
    output reg valid
);
    // Alternative priority encoder implementation
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            grant <= 4'b0000;
            valid <= 1'b0;
        end
        else begin
            grant <= 4'b0000;
            valid <= 1'b0;
            
            // Different priority encoding logic
            if (req[3]) begin
                grant[3] <= 1'b1;
                valid <= 1'b1;
            end
            else if (req[2]) begin
                grant[2] <= 1'b1;
                valid <= 1'b1;
            end
            else if (req[1]) begin
                grant[1] <= 1'b1;
                valid <= 1'b1;
            end
            else if (req[0]) begin
                grant[0] <= 1'b1;
                valid <= 1'b1;
            end
        end
    end
endmodule

// Fault detection and output selection module
module FaultDetector (
    input [3:0] grant_a,
    input [3:0] grant_b,
    input valid_a,
    input valid_b,
    output reg [3:0] grant
);
    // Fault detection logic
    always @(*) begin
        if (valid_a && valid_b && grant_a == grant_b) begin
            grant = grant_a;
        end
        else begin
            grant = 4'b0000;
        end
    end
endmodule

// 4-bit Karatsuba Multiplier Module
module KaratsubaMultiplier (
    input [3:0] a,
    input [3:0] b,
    output [7:0] result
);
    // Internal signals for Karatsuba algorithm
    wire [1:0] a_high, a_low, b_high, b_low;
    wire [3:0] z0, z1, z2;
    wire [3:0] temp1, temp2;
    
    // Split operands into high and low parts
    assign a_high = a[3:2];
    assign a_low = a[1:0];
    assign b_high = b[3:2];
    assign b_low = b[1:0];
    
    // Calculate z0 = a_low * b_low
    assign z0 = a_low * b_low;
    
    // Calculate z2 = a_high * b_high
    assign z2 = a_high * b_high;
    
    // Calculate z1 = (a_high + a_low) * (b_high + b_low) - z0 - z2
    assign temp1 = a_high + a_low;
    assign temp2 = b_high + b_low;
    assign z1 = (temp1 * temp2) - z0 - z2;
    
    // Combine results
    assign result = (z2 << 4) + (z1 << 2) + z0;
endmodule

// 2-bit multiplier for Karatsuba algorithm
module TwoBitMultiplier (
    input [1:0] a,
    input [1:0] b,
    output [3:0] result
);
    // Direct multiplication for 2-bit operands
    assign result = a * b;
endmodule