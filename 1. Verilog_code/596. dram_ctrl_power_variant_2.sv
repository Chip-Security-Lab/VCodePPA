//SystemVerilog
module dram_ctrl_power #(
    parameter LOW_POWER_THRESH = 100
)(
    input clk,
    input rst_n,
    input activity,
    output reg clk_en
);

    // Stage 1: Activity Detection
    reg activity_stage1;
    reg [7:0] idle_counter_stage1;
    
    // Stage 2: Counter Update
    reg activity_stage2;
    reg [7:0] idle_counter_stage2;
    
    // Stage 3: Power Control
    reg activity_stage3;
    reg [7:0] idle_counter_stage3;
    
    // Pipeline Control
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Han-Carlson Adder Signals
    wire [7:0] han_carlson_sum;
    wire han_carlson_cout;
    
    // Han-Carlson Adder Instance
    han_carlson_adder #(.WIDTH(8)) han_carlson_inst (
        .a(idle_counter_stage1),
        .b(8'b00000001),
        .cin(1'b0),
        .sum(han_carlson_sum),
        .cout(han_carlson_cout)
    );
    
    // Stage 1: Activity Detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            activity_stage1 <= 0;
            idle_counter_stage1 <= 0;
            valid_stage1 <= 0;
        end else begin
            activity_stage1 <= activity;
            idle_counter_stage1 <= idle_counter_stage3;
            valid_stage1 <= 1;
        end
    end
    
    // Stage 2: Counter Update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            activity_stage2 <= 0;
            idle_counter_stage2 <= 0;
            valid_stage2 <= 0;
        end else begin
            activity_stage2 <= activity_stage1;
            if (activity_stage1) begin
                idle_counter_stage2 <= 0;
            end else if (idle_counter_stage1 < LOW_POWER_THRESH) begin
                idle_counter_stage2 <= han_carlson_sum;
            end else begin
                idle_counter_stage2 <= idle_counter_stage1;
            end
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Stage 3: Power Control
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            activity_stage3 <= 0;
            idle_counter_stage3 <= 0;
            clk_en <= 1;
            valid_stage3 <= 0;
        end else begin
            activity_stage3 <= activity_stage2;
            idle_counter_stage3 <= idle_counter_stage2;
            if (activity_stage2) begin
                clk_en <= 1;
            end else if (idle_counter_stage2 < LOW_POWER_THRESH) begin
                clk_en <= 1;
            end else begin
                clk_en <= 0;
            end
            valid_stage3 <= valid_stage2;
        end
    end

endmodule

// Han-Carlson Adder Module
module han_carlson_adder #(
    parameter WIDTH = 8
)(
    input [WIDTH-1:0] a,
    input [WIDTH-1:0] b,
    input cin,
    output [WIDTH-1:0] sum,
    output cout
);

    // Generate and Propagate signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] g_out, p_out;
    
    // First level: Generate and Propagate
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_prop
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] ^ b[i];
        end
    endgenerate
    
    // Second level: Group Generate and Propagate
    wire [WIDTH/2-1:0] g_group, p_group;
    generate
        for (i = 0; i < WIDTH/2; i = i + 1) begin : group_gen_prop
            assign g_group[i] = g[2*i+1] | (p[2*i+1] & g[2*i]);
            assign p_group[i] = p[2*i+1] & p[2*i];
        end
    endgenerate
    
    // Third level: Final Group Generate and Propagate
    wire g_final, p_final;
    assign g_final = g_group[WIDTH/2-1] | (p_group[WIDTH/2-1] & g_group[WIDTH/2-2]);
    assign p_final = p_group[WIDTH/2-1] & p_group[WIDTH/2-2];
    
    // Carry computation
    wire [WIDTH-1:0] carry;
    assign carry[0] = cin;
    assign carry[1] = g[0] | (p[0] & cin);
    
    generate
        for (i = 2; i < WIDTH; i = i + 2) begin : carry_compute
            assign carry[i] = g[i-1] | (p[i-1] & carry[i-1]);
            assign carry[i+1] = g[i] | (p[i] & carry[i]);
        end
    endgenerate
    
    // Sum computation
    assign sum[0] = p[0] ^ cin;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : sum_compute
            assign sum[i] = p[i] ^ carry[i];
        end
    endgenerate
    
    // Final carry out
    assign cout = g_final | (p_final & cin);

endmodule