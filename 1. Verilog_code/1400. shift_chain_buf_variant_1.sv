//SystemVerilog
// SystemVerilog - IEEE 1364-2005 Verilog标准
module shift_chain_buf #(parameter DW=8, DEPTH=4) (
    input clk, en,
    input serial_in,
    input [DW-1:0] parallel_in,
    input load,
    input rst,
    output serial_out,
    output [DW*DEPTH-1:0] parallel_out
);
    wire [DW-1:0] processed_data;
    
    // Instantiate the carry-skip adder to process data
    carry_skip_adder #(.WIDTH(DW)) csa_inst (
        .a(parallel_in),
        .b(8'h01),  // Add 1 to the input data
        .cin(1'b0),
        .sum(processed_data),
        .cout()     // Unused output
    );
    
    reg [DW-1:0] shift_reg [0:DEPTH-1];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            integer i;
            for(i=0; i<DEPTH; i=i+1)
                shift_reg[i] <= 0;
        end else if(en) begin
            if(load) begin
                // Use processed data from carry-skip adder
                shift_reg[0] <= processed_data;
                shift_reg[1] <= processed_data;
                shift_reg[2] <= processed_data;
                shift_reg[3] <= processed_data;
            end
            else begin
                shift_reg[3] <= shift_reg[2];
                shift_reg[2] <= shift_reg[1];
                shift_reg[1] <= shift_reg[0];
                shift_reg[0] <= {{(DW-1){1'b0}}, serial_in};
            end
        end
    end
    
    assign serial_out = shift_reg[DEPTH-1][0];
    
    genvar g;
    generate
        for(g=0; g<DEPTH; g=g+1)
            assign parallel_out[g*DW +: DW] = shift_reg[g];
    endgenerate
endmodule

// 8-bit Carry Skip Adder implementation
module carry_skip_adder #(parameter WIDTH=8) (
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);
    // Group size for skip logic (2-bit groups for 8-bit adder)
    localparam GROUP_SIZE = 2;
    localparam NUM_GROUPS = WIDTH / GROUP_SIZE;
    
    // Internal signals
    wire [WIDTH:0] carry;
    wire [NUM_GROUPS-1:0] bypass;
    
    // Input carry
    assign carry[0] = cin;
    
    // Generate carry skip adder logic for each group
    genvar i, j;
    generate
        for (i = 0; i < NUM_GROUPS; i = i + 1) begin: groups
            // Propagate signals for each bit in the group
            wire [GROUP_SIZE-1:0] p;
            wire [GROUP_SIZE-1:0] internal_carry;
            
            // Group bypass signal (AND of all propagate signals in the group)
            wire group_p;
            
            // Calculate each bit in the group
            for (j = 0; j < GROUP_SIZE; j = j + 1) begin: bits
                localparam bit_idx = i * GROUP_SIZE + j;
                
                // Propagate signal
                assign p[j] = a[bit_idx] ^ b[bit_idx];
                
                // Sum calculation
                if (j == 0) begin: first_bit
                    assign internal_carry[0] = a[bit_idx] & b[bit_idx];
                    assign sum[bit_idx] = p[j] ^ carry[i*GROUP_SIZE];
                end else begin: other_bits
                    assign internal_carry[j] = (a[bit_idx] & b[bit_idx]) | 
                                               (p[j-1] & internal_carry[j-1]);
                    assign sum[bit_idx] = p[j] ^ internal_carry[j-1];
                end
            end
            
            // Group propagate signal (AND of all propagate signals)
            assign group_p = &p;
            
            // Skip logic using if-else structure instead of conditional operator
            // Original: assign carry[(i+1)*GROUP_SIZE] = group_p ? carry[i*GROUP_SIZE] : internal_carry[GROUP_SIZE-1];
            reg temp_carry;
            always @(*) begin
                if (group_p) begin
                    temp_carry = carry[i*GROUP_SIZE];
                end else begin
                    temp_carry = internal_carry[GROUP_SIZE-1];
                end
            end
            assign carry[(i+1)*GROUP_SIZE] = temp_carry;
        end
    endgenerate
    
    // Final carry out
    assign cout = carry[WIDTH];
endmodule