//SystemVerilog
// Top module
module quad_encoder_timer (
    input wire clk, rst, quad_a, quad_b, timer_en,
    output wire [15:0] position,
    output wire [31:0] timer
);
    // Internal signals
    wire a_prev, b_prev;
    wire count_up, count_down;
    wire position_update;
    wire [15:0] next_position;
    wire [31:0] next_timer;

    // Instantiate the encoder edge detection module
    quad_edge_detector u_edge_detector (
        .clk(clk),
        .rst(rst),
        .quad_a(quad_a),
        .quad_b(quad_b),
        .a_prev(a_prev),
        .b_prev(b_prev),
        .position_update(position_update)
    );

    // Instantiate the position calculation module (combinational)
    position_calculator u_pos_calc (
        .quad_a(quad_a),
        .quad_b(quad_b),
        .a_prev(a_prev),
        .b_prev(b_prev),
        .current_position(position),
        .position_update(position_update),
        .count_up(count_up),
        .count_down(count_down),
        .next_position(next_position)
    );

    // Instantiate the timer calculation module with parallel prefix adder
    timer_calculator_ppa u_timer_calc (
        .timer_en(timer_en),
        .current_timer(timer),
        .next_timer(next_timer)
    );

    // Instantiate the registers module (sequential)
    quad_registers u_registers (
        .clk(clk),
        .rst(rst),
        .next_position(next_position),
        .next_timer(next_timer),
        .position_update(position_update),
        .position(position),
        .timer(timer)
    );
endmodule

// Edge detection module (sequential)
module quad_edge_detector (
    input wire clk, rst, quad_a, quad_b,
    output reg a_prev, b_prev,
    output wire position_update
);
    // Sequential block for edge detection
    always @(posedge clk) begin
        if (rst) begin
            a_prev <= 1'b0;
            b_prev <= 1'b0;
        end
        else begin
            a_prev <= quad_a;
            b_prev <= quad_b;
        end
    end

    // Combinational logic to detect when to update position
    assign position_update = (quad_a != a_prev) || (quad_b != b_prev);
endmodule

// Position calculation module (combinational)
module position_calculator (
    input wire quad_a, quad_b, a_prev, b_prev,
    input wire [15:0] current_position,
    input wire position_update,
    output wire count_up, count_down,
    output wire [15:0] next_position
);
    // Combinational logic for direction detection
    assign count_up = quad_a ^ b_prev;
    assign count_down = quad_b ^ a_prev;

    // Combinational logic for next position calculation
    assign next_position = position_update ? 
                          (count_up ? current_position + 16'h0001 : 
                          (count_down ? current_position - 16'h0001 : current_position)) :
                          current_position;
endmodule

// Timer calculation module with parallel prefix adder (combinational)
module timer_calculator_ppa (
    input wire timer_en,
    input wire [31:0] current_timer,
    output wire [31:0] next_timer
);
    // Internal signals for parallel prefix adder
    wire [31:0] p; // Propagate signals
    wire [31:0] g; // Generate signals
    wire [31:0] c; // Carry signals
    
    // Generate the increment value based on timer_en
    wire [31:0] increment = timer_en ? 32'h1 : 32'h0;
    
    // Stage 1: Generate propagate and generate signals
    assign p = current_timer | increment; // Propagate
    assign g = current_timer & increment; // Generate
    
    // Stage 2: Parallel prefix computation (Kogge-Stone algorithm)
    // Level 1
    wire [31:0] p_l1, g_l1;
    
    assign p_l1[0] = p[0];
    assign g_l1[0] = g[0];
    
    generate
        for (genvar i = 1; i < 32; i = i + 1) begin : level1
            assign p_l1[i] = p[i] & p[i-1];
            assign g_l1[i] = g[i] | (p[i] & g[i-1]);
        end
    endgenerate
    
    // Level 2
    wire [31:0] p_l2, g_l2;
    
    assign p_l2[0] = p_l1[0];
    assign g_l2[0] = g_l1[0];
    assign p_l2[1] = p_l1[1];
    assign g_l2[1] = g_l1[1];
    
    generate
        for (genvar i = 2; i < 32; i = i + 1) begin : level2
            assign p_l2[i] = p_l1[i] & p_l1[i-2];
            assign g_l2[i] = g_l1[i] | (p_l1[i] & g_l1[i-2]);
        end
    endgenerate
    
    // Level 3
    wire [31:0] p_l3, g_l3;
    
    assign p_l3[0] = p_l2[0];
    assign g_l3[0] = g_l2[0];
    assign p_l3[1] = p_l2[1];
    assign g_l3[1] = g_l2[1];
    assign p_l3[2] = p_l2[2];
    assign g_l3[2] = g_l2[2];
    assign p_l3[3] = p_l2[3];
    assign g_l3[3] = g_l2[3];
    
    generate
        for (genvar i = 4; i < 32; i = i + 1) begin : level3
            assign p_l3[i] = p_l2[i] & p_l2[i-4];
            assign g_l3[i] = g_l2[i] | (p_l2[i] & g_l2[i-4]);
        end
    endgenerate
    
    // Level 4
    wire [31:0] p_l4, g_l4;
    
    generate
        for (genvar i = 0; i < 8; i = i + 1) begin : level4_low
            assign p_l4[i] = p_l3[i];
            assign g_l4[i] = g_l3[i];
        end
    endgenerate
    
    generate
        for (genvar i = 8; i < 32; i = i + 1) begin : level4
            assign p_l4[i] = p_l3[i] & p_l3[i-8];
            assign g_l4[i] = g_l3[i] | (p_l3[i] & g_l3[i-8]);
        end
    endgenerate
    
    // Level 5
    wire [31:0] p_l5, g_l5;
    
    generate
        for (genvar i = 0; i < 16; i = i + 1) begin : level5_low
            assign p_l5[i] = p_l4[i];
            assign g_l5[i] = g_l4[i];
        end
    endgenerate
    
    generate
        for (genvar i = 16; i < 32; i = i + 1) begin : level5
            assign p_l5[i] = p_l4[i] & p_l4[i-16];
            assign g_l5[i] = g_l4[i] | (p_l4[i] & g_l4[i-16]);
        end
    endgenerate
    
    // Stage 3: Generate carries
    assign c[0] = 1'b0; // No carry-in for LSB
    assign c[31:1] = g_l5[30:0]; // Carry is the generate signal from previous bit
    
    // Stage 4: Compute sum
    assign next_timer = current_timer ^ increment ^ c;
endmodule

// Registers module (sequential)
module quad_registers (
    input wire clk, rst,
    input wire [15:0] next_position,
    input wire [31:0] next_timer,
    input wire position_update,
    output reg [15:0] position,
    output reg [31:0] timer
);
    // Sequential block for position register
    always @(posedge clk) begin
        if (rst) begin
            position <= 16'h0000;
        end
        else begin
            position <= next_position;
        end
    end

    // Sequential block for timer register
    always @(posedge clk) begin
        if (rst) begin
            timer <= 32'h0;
        end
        else begin
            timer <= next_timer;
        end
    end
endmodule