//SystemVerilog
`timescale 1ns / 1ps
module program_range_decoder(
    input wire clk,            // Clock signal
    input wire rst_n,          // Active low reset
    
    // Input interface
    input wire [7:0] addr,
    input wire [7:0] base_addr,
    input wire [7:0] limit,
    input wire valid_in,       // Input valid signal
    output wire ready_in,      // Input ready signal
    
    // Output interface
    output wire in_range,
    output wire valid_out,     // Output valid signal
    input wire ready_out       // Output ready signal
);
    // Internal signals
    wire is_addr_greater_equal;
    wire is_addr_less_than;
    wire [7:0] upper_bound;
    
    // Pipeline registers
    reg [7:0] addr_reg, base_addr_reg, limit_reg;
    reg valid_stage1, valid_stage2;
    wire ready_stage1, ready_stage2;
    
    // Stage 1: Input interface and address bound calculation
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            addr_reg <= 8'b0;
            base_addr_reg <= 8'b0;
            limit_reg <= 8'b0;
            valid_stage1 <= 1'b0;
        end else if (valid_in && ready_in) begin
            addr_reg <= addr;
            base_addr_reg <= base_addr;
            limit_reg <= limit;
            valid_stage1 <= 1'b1;
        end else if (ready_stage1) begin
            valid_stage1 <= 1'b0;
        end
    end
    
    // Calculate upper bound
    addr_bound_calculator addr_bound_calc_inst (
        .clk(clk),
        .rst_n(rst_n),
        .base_addr(base_addr_reg),
        .limit(limit_reg),
        .valid_in(valid_stage1),
        .ready_in(ready_stage1),
        .upper_bound(upper_bound),
        .valid_out(valid_stage2),
        .ready_out(ready_stage2)
    );
    
    // Compare address with bounds
    addr_comparator addr_comp_inst (
        .clk(clk),
        .rst_n(rst_n),
        .addr(addr_reg),
        .base_addr(base_addr_reg),
        .upper_bound(upper_bound),
        .valid_in(valid_stage2),
        .ready_in(ready_stage2),
        .is_addr_greater_equal(is_addr_greater_equal),
        .is_addr_less_than(is_addr_less_than),
        .valid_out(valid_out),
        .ready_out(ready_out)
    );
    
    // Determine final range check result
    range_detector range_detect_inst (
        .is_addr_greater_equal(is_addr_greater_equal),
        .is_addr_less_than(is_addr_less_than),
        .in_range(in_range)
    );
    
    // Ready propagation (backpressure)
    assign ready_in = (~valid_stage1) || ready_stage1;
endmodule

// Calculates the upper bound of the address range using carry-select adder
module addr_bound_calculator(
    input wire clk,
    input wire rst_n,
    input wire [7:0] base_addr,
    input wire [7:0] limit,
    input wire valid_in,
    output wire ready_in,
    output wire [7:0] upper_bound,
    output wire valid_out,
    input wire ready_out
);
    // Internal signals for carry-select adder
    wire [3:0] sum_lower0, sum_lower1;
    wire [3:0] sum_upper0, sum_upper1;
    wire carry_lower;
    reg [7:0] sum_reg;
    reg valid_reg;
    
    // Lower 4 bits adder (always uses carry-in = 0)
    ripple_carry_adder_4bit lower_add0 (
        .a(base_addr[3:0]),
        .b(limit[3:0]),
        .cin(1'b0),
        .sum(sum_lower0),
        .cout(carry_lower)
    );
    
    // Upper 4 bits adders with carry-in = 0 and carry-in = 1
    ripple_carry_adder_4bit upper_add0 (
        .a(base_addr[7:4]),
        .b(limit[7:4]),
        .cin(1'b0),
        .sum(sum_upper0),
        .cout()
    );
    
    ripple_carry_adder_4bit upper_add1 (
        .a(base_addr[7:4]),
        .b(limit[7:4]),
        .cin(1'b1),
        .sum(sum_upper1),
        .cout()
    );
    
    // Select the correct upper sum based on the carry from lower bits
    wire [7:0] sum;
    assign sum[3:0] = sum_lower0;
    assign sum[7:4] = carry_lower ? sum_upper1 : sum_upper0;
    
    // Register stage for handshaking
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            sum_reg <= 8'b0;
            valid_reg <= 1'b0;
        end else if (valid_in && ready_in) begin
            sum_reg <= sum;
            valid_reg <= 1'b1;
        end else if (valid_reg && ready_out) begin
            valid_reg <= 1'b0;
        end
    end
    
    // Output assignment
    assign upper_bound = sum_reg;
    assign valid_out = valid_reg;
    assign ready_in = (~valid_reg) || ready_out;
endmodule

// 4-bit ripple carry adder for carry-select implementation
module ripple_carry_adder_4bit(
    input [3:0] a,
    input [3:0] b,
    input cin,
    output [3:0] sum,
    output cout
);
    wire [4:0] carry;
    assign carry[0] = cin;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : full_adder_gen
            full_adder fa (
                .a(a[i]),
                .b(b[i]),
                .cin(carry[i]),
                .sum(sum[i]),
                .cout(carry[i+1])
            );
        end
    endgenerate
    
    assign cout = carry[4];
endmodule

// Full adder for a single bit
module full_adder(
    input a,
    input b,
    input cin,
    output sum,
    output cout
);
    assign sum = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

// Compares address with lower and upper bounds
module addr_comparator(
    input wire clk,
    input wire rst_n,
    input wire [7:0] addr,
    input wire [7:0] base_addr,
    input wire [7:0] upper_bound,
    input wire valid_in,
    output wire ready_in,
    output wire is_addr_greater_equal,
    output wire is_addr_less_than,
    output wire valid_out,
    input wire ready_out
);
    // Comparison logic
    wire is_greater_equal = (addr >= base_addr);
    wire is_less_than = (addr < upper_bound);
    
    // Pipeline registers
    reg is_greater_equal_reg, is_less_than_reg;
    reg valid_reg;
    
    // Register stage with handshaking
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            is_greater_equal_reg <= 1'b0;
            is_less_than_reg <= 1'b0;
            valid_reg <= 1'b0;
        end else if (valid_in && ready_in) begin
            is_greater_equal_reg <= is_greater_equal;
            is_less_than_reg <= is_less_than;
            valid_reg <= 1'b1;
        end else if (valid_reg && ready_out) begin
            valid_reg <= 1'b0;
        end
    end
    
    // Output assignments
    assign is_addr_greater_equal = is_greater_equal_reg;
    assign is_addr_less_than = is_less_than_reg;
    assign valid_out = valid_reg;
    assign ready_in = (~valid_reg) || ready_out;
endmodule

// Determines if the address is within range based on comparison results
module range_detector(
    input is_addr_greater_equal,
    input is_addr_less_than,
    output in_range
);
    assign in_range = is_addr_greater_equal && is_addr_less_than;
endmodule