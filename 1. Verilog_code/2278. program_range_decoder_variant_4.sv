//SystemVerilog
module program_range_decoder(
    input logic clk,
    input logic rst_n,
    // Input interface
    input logic [7:0] addr,
    input logic [7:0] base_addr,
    input logic [7:0] limit,
    input logic input_valid,
    output logic input_ready,
    // Output interface
    output logic in_range,
    output logic output_valid,
    input logic output_ready
);
    logic [7:0] sum;
    logic carry_out;
    logic adder_valid;
    logic adder_ready;
    
    // Input registers
    logic [7:0] addr_reg, base_addr_reg, limit_reg;
    logic input_valid_reg;
    
    // Output registers
    logic in_range_reg;
    logic output_valid_reg;
    
    // Input handshaking
    assign input_ready = !input_valid_reg || (output_valid_reg && output_ready);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_reg <= 8'b0;
            base_addr_reg <= 8'b0;
            limit_reg <= 8'b0;
            input_valid_reg <= 1'b0;
        end else if (input_ready && input_valid) begin
            addr_reg <= addr;
            base_addr_reg <= base_addr;
            limit_reg <= limit;
            input_valid_reg <= 1'b1;
        end else if (output_valid_reg && output_ready) begin
            input_valid_reg <= 1'b0;
        end
    end
    
    // Instantiate adder with valid-ready interface
    skip_carry_adder adder_inst(
        .clk(clk),
        .rst_n(rst_n),
        .a(base_addr_reg),
        .b(limit_reg),
        .input_valid(input_valid_reg),
        .input_ready(adder_ready),
        .sum(sum),
        .cout(carry_out),
        .output_valid(adder_valid),
        .output_ready(output_valid_reg && output_ready)
    );
    
    // Calculate result
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_range_reg <= 1'b0;
            output_valid_reg <= 1'b0;
        end else if (adder_valid && !output_valid_reg) begin
            in_range_reg <= (addr_reg >= base_addr_reg) && (addr_reg < sum);
            output_valid_reg <= 1'b1;
        end else if (output_valid_reg && output_ready) begin
            output_valid_reg <= 1'b0;
        end
    end
    
    // Output assignment
    assign in_range = in_range_reg;
    assign output_valid = output_valid_reg;
    
endmodule

module skip_carry_adder(
    input logic clk,
    input logic rst_n,
    // Input interface
    input logic [7:0] a,
    input logic [7:0] b,
    input logic input_valid,
    output logic input_ready,
    // Output interface
    output logic [7:0] sum,
    output logic cout,
    output logic output_valid,
    input logic output_ready
);
    // Internal signals
    logic [7:0] p; // Propagate signals
    logic [8:0] c; // Carry signals (includes carry-in and carry-out)
    logic [1:0] block_p; // Block propagate signals
    
    // Input/Output registers
    logic [7:0] a_reg, b_reg;
    logic [7:0] sum_reg;
    logic cout_reg;
    logic calc_in_progress;
    logic output_valid_reg;
    
    // Input handshaking
    assign input_ready = !calc_in_progress || (output_valid_reg && output_ready);
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            a_reg <= 8'b0;
            b_reg <= 8'b0;
            calc_in_progress <= 1'b0;
        end else if (input_ready && input_valid) begin
            a_reg <= a;
            b_reg <= b;
            calc_in_progress <= 1'b1;
        end else if (output_valid_reg && output_ready) begin
            calc_in_progress <= 1'b0;
        end
    end
    
    // Generate propagate signals for each bit
    assign p = a_reg ^ b_reg;
    
    // Set carry-in to 0
    assign c[0] = 1'b0;
    
    // First block (bits 0-3)
    assign c[1] = a_reg[0] & b_reg[0] | (p[0] & c[0]);
    assign c[2] = a_reg[1] & b_reg[1] | (p[1] & c[1]);
    assign c[3] = a_reg[2] & b_reg[2] | (p[2] & c[2]);
    assign c[4] = a_reg[3] & b_reg[3] | (p[3] & c[3]);
    
    // Second block (bits 4-7)
    assign c[5] = a_reg[4] & b_reg[4] | (p[4] & c[4]);
    assign c[6] = a_reg[5] & b_reg[5] | (p[5] & c[5]);
    assign c[7] = a_reg[6] & b_reg[6] | (p[6] & c[6]);
    assign c[8] = a_reg[7] & b_reg[7] | (p[7] & c[7]);
    
    // Block propagate signals
    assign block_p[0] = &p[3:0]; // AND of all propagate signals in first block
    assign block_p[1] = &p[7:4]; // AND of all propagate signals in second block
    
    // Skip logic for second block
    logic skip_carry;
    assign skip_carry = c[4] | (block_p[1] & c[8]);
    
    // Generate sum (combinational)
    logic [7:0] sum_comb;
    assign sum_comb = p ^ {c[7:0]};
    
    // Output stage
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sum_reg <= 8'b0;
            cout_reg <= 1'b0;
            output_valid_reg <= 1'b0;
        end else if (calc_in_progress && !output_valid_reg) begin
            sum_reg <= sum_comb;
            cout_reg <= c[8];
            output_valid_reg <= 1'b1;
        end else if (output_valid_reg && output_ready) begin
            output_valid_reg <= 1'b0;
        end
    end
    
    // Output assignment
    assign sum = sum_reg;
    assign cout = cout_reg;
    assign output_valid = output_valid_reg;
    
endmodule