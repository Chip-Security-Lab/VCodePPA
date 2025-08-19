//SystemVerilog
module usb_endpoint_buffer_mgr #(
    parameter NUM_ENDPOINTS = 4,
    parameter BUFFER_SIZE = 64
)(
    input wire clk,
    input wire rst_b,
    input wire [3:0] endpoint_select,
    input wire write_enable,
    input wire read_enable,
    input wire [7:0] write_data,
    output reg [7:0] read_data,
    output reg buffer_full,
    output reg buffer_empty,
    output reg [7:0] buffer_count
);
    // RAM for each endpoint buffer
    reg [7:0] buffers [0:NUM_ENDPOINTS-1][0:BUFFER_SIZE-1];
    
    // Pointers and counters for each endpoint
    reg [7:0] write_ptr [0:NUM_ENDPOINTS-1];
    reg [7:0] read_ptr [0:NUM_ENDPOINTS-1];
    reg [7:0] count [0:NUM_ENDPOINTS-1];
    
    // Current endpoint's pointers
    wire [7:0] curr_write_ptr = write_ptr[endpoint_select];
    wire [7:0] curr_read_ptr = read_ptr[endpoint_select];
    wire [7:0] curr_count = count[endpoint_select];
    
    // Wires for Brent-Kung adder
    wire [7:0] new_count_inc, new_count_dec;
    wire [7:0] new_write_ptr, new_read_ptr;
    
    // Instantiate Brent-Kung adders
    brent_kung_adder #(.WIDTH(8)) adder_inc (
        .a(curr_count),
        .b(8'd1),
        .cin(1'b0),
        .sum(new_count_inc),
        .cout()
    );
    
    brent_kung_adder #(.WIDTH(8)) adder_dec (
        .a(curr_count),
        .b(8'hFF), // -1 in 2's complement
        .cin(1'b1),
        .sum(new_count_dec),
        .cout()
    );
    
    brent_kung_adder #(.WIDTH(8)) adder_write_ptr (
        .a(curr_write_ptr),
        .b(8'd1),
        .cin(1'b0),
        .sum(new_write_ptr),
        .cout()
    );
    
    brent_kung_adder #(.WIDTH(8)) adder_read_ptr (
        .a(curr_read_ptr),
        .b(8'd1),
        .cin(1'b0),
        .sum(new_read_ptr),
        .cout()
    );
    
    // Modulo operation wires
    wire [7:0] new_write_ptr_mod = (new_write_ptr >= BUFFER_SIZE) ? 8'd0 : new_write_ptr;
    wire [7:0] new_read_ptr_mod = (new_read_ptr >= BUFFER_SIZE) ? 8'd0 : new_read_ptr;
    
    integer i;
    always @(posedge clk or negedge rst_b) begin
        if (!rst_b) begin
            for (i = 0; i < NUM_ENDPOINTS; i = i + 1) begin
                write_ptr[i] <= 8'd0;
                read_ptr[i] <= 8'd0;
                count[i] <= 8'd0;
            end
            buffer_full <= 1'b0;
            buffer_empty <= 1'b1;
            buffer_count <= 8'd0;
        end else begin
            // Update status flags for currently selected endpoint
            buffer_full <= (curr_count == BUFFER_SIZE);
            buffer_empty <= (curr_count == 8'd0);
            buffer_count <= curr_count;
            
            // Process write request
            if (write_enable && !buffer_full) begin
                buffers[endpoint_select][curr_write_ptr] <= write_data;
                write_ptr[endpoint_select] <= new_write_ptr_mod;
                count[endpoint_select] <= new_count_inc;
            end
            
            // Process read request
            if (read_enable && !buffer_empty) begin
                read_data <= buffers[endpoint_select][curr_read_ptr];
                read_ptr[endpoint_select] <= new_read_ptr_mod;
                count[endpoint_select] <= new_count_dec;
            end
        end
    end
endmodule

// Brent-Kung adder module
module brent_kung_adder #(
    parameter WIDTH = 8
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum,
    output wire cout
);
    // Generate (G) and Propagate (P) signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH:0] c;
    
    // Group generate and propagate signals
    wire [WIDTH/2-1:0] g_group1, p_group1;
    wire [WIDTH/4-1:0] g_group2, p_group2;
    wire [WIDTH/8-1:0] g_group3, p_group3;
    
    // Carry signals
    assign c[0] = cin;
    
    // Stage 1: Generate initial G and P signals
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_gp
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // Stage 2: Group 1 (pairs)
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin: gen_group1
            assign g_group1[i] = g[2*i+1] | (p[2*i+1] & g[2*i]);
            assign p_group1[i] = p[2*i+1] & p[2*i];
        end
    endgenerate
    
    // Stage 3: Group 2 (groups of 4)
    generate
        for (i = 0; i < WIDTH/4; i = i + 1) begin: gen_group2
            assign g_group2[i] = g_group1[2*i+1] | (p_group1[2*i+1] & g_group1[2*i]);
            assign p_group2[i] = p_group1[2*i+1] & p_group1[2*i];
        end
    endgenerate
    
    // Stage 4: Group 3 (groups of 8) - only needed for WIDTH >= 8
    generate
        if (WIDTH >= 8) begin
            for (i = 0; i < WIDTH/8; i = i + 1) begin: gen_group3
                assign g_group3[i] = g_group2[2*i+1] | (p_group2[2*i+1] & g_group2[2*i]);
                assign p_group3[i] = p_group2[2*i+1] & p_group2[2*i];
            end
        end
    endgenerate
    
    // Stage 5: Calculate carries using Brent-Kung tree
    // First level carries
    assign c[1] = g[0] | (p[0] & c[0]);
    
    // Second level carries (based on WIDTH)
    generate
        if (WIDTH >= 2) begin
            assign c[2] = g[1] | (p[1] & c[1]);
            assign c[4] = g_group1[1] | (p_group1[1] & c[2]);
        end
        if (WIDTH >= 4) begin
            assign c[3] = g[2] | (p[2] & c[2]);
            assign c[6] = g_group1[2] | (p_group1[2] & c[4]);
        end
        if (WIDTH >= 8) begin
            assign c[5] = g[4] | (p[4] & c[4]);
            assign c[7] = g[6] | (p[6] & c[6]);
            assign c[8] = g_group2[1] | (p_group2[1] & c[4]);
        end
    endgenerate
    
    // Stage 6: Calculate final sum
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin: gen_sum
            assign sum[i] = p[i] ^ c[i];
        end
    endgenerate
    
    // Carry out
    assign cout = c[WIDTH];
endmodule