//SystemVerilog
module crossbar_monitor #(DW=8, N=4) (
    input wire clk,
    input wire rst_n,
    input wire [N-1:0][DW-1:0] din,
    input wire valid_in,
    output wire valid_out,
    output wire [N-1:0][DW-1:0] dout,
    output wire [31:0] traffic_count
);
    // Stage 1 registers - Input stage
    reg [N-1:0][DW-1:0] din_stage1;
    reg valid_stage1;
    
    // Stage 2 registers - Processing stage
    reg [N-1:0][DW-1:0] dout_stage2;
    reg valid_stage2;
    reg [31:0] traffic_incr_stage2;
    
    // Stage 3 registers - Output stage
    reg [N-1:0][DW-1:0] dout_stage3;
    reg valid_stage3;
    reg [31:0] traffic_count_reg;
    
    // Parallel prefix adder signals for traffic counter
    wire [31:0] current_count;
    wire [31:0] increment;
    wire [31:0] new_count;
    wire [31:0] p_sum [0:4]; // Propagation sum for parallel prefix addition
    wire [31:0] g_sum [0:4]; // Generation sum for parallel prefix addition
    
    integer i;
    
    // Stage 1: Input registration and traffic detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage1 <= {(N*DW){1'b0}};
            valid_stage1 <= 1'b0;
        end else begin
            din_stage1 <= din;
            valid_stage1 <= valid_in;
        end
    end
    
    // Stage 2: Process data and calculate traffic increment
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage2 <= {(N*DW){1'b0}};
            valid_stage2 <= 1'b0;
            traffic_incr_stage2 <= 32'd0;
        end else begin
            valid_stage2 <= valid_stage1;
            traffic_incr_stage2 <= 32'd0; // Reset traffic increment counter
            
            for (i = 0; i < N; i = i + 1) begin
                // Connect inputs to corresponding outputs in reverse order
                dout_stage2[i] <= din_stage1[N-1-i];
                
                // Count traffic based on non-zero inputs
                if (|din_stage1[i]) begin
                    traffic_incr_stage2 <= traffic_incr_stage2 + 1'b1;
                end
            end
        end
    end
    
    // Parallel prefix adder implementation for traffic counter
    assign current_count = traffic_count_reg;
    assign increment = valid_stage2 ? traffic_incr_stage2 : 32'd0;
    
    // Level 0 - Generate propagate (p) and generate (g) signals
    assign p_sum[0] = ~current_count;
    assign g_sum[0] = increment;
    
    // Level 1 - First level of prefix computation
    assign p_sum[1][31:16] = p_sum[0][31:16] & p_sum[0][15:0];
    assign g_sum[1][31:16] = g_sum[0][31:16] | (p_sum[0][31:16] & g_sum[0][15:0]);
    assign p_sum[1][15:0] = p_sum[0][15:0];
    assign g_sum[1][15:0] = g_sum[0][15:0];
    
    // Level 2 - Second level of prefix computation
    assign p_sum[2][31:24] = p_sum[1][31:24] & p_sum[1][23:16];
    assign g_sum[2][31:24] = g_sum[1][31:24] | (p_sum[1][31:24] & g_sum[1][23:16]);
    assign p_sum[2][23:16] = p_sum[1][23:16];
    assign g_sum[2][23:16] = g_sum[1][23:16];
    assign p_sum[2][15:8] = p_sum[1][15:8] & p_sum[1][7:0];
    assign g_sum[2][15:8] = g_sum[1][15:8] | (p_sum[1][15:8] & g_sum[1][7:0]);
    assign p_sum[2][7:0] = p_sum[1][7:0];
    assign g_sum[2][7:0] = g_sum[1][7:0];
    
    // Level 3 - Third level of prefix computation
    assign p_sum[3][31:28] = p_sum[2][31:28] & p_sum[2][27:24];
    assign g_sum[3][31:28] = g_sum[2][31:28] | (p_sum[2][31:28] & g_sum[2][27:24]);
    assign p_sum[3][27:24] = p_sum[2][27:24];
    assign g_sum[3][27:24] = g_sum[2][27:24];
    assign p_sum[3][23:20] = p_sum[2][23:20] & p_sum[2][19:16];
    assign g_sum[3][23:20] = g_sum[2][23:20] | (p_sum[2][23:20] & g_sum[2][19:16]);
    assign p_sum[3][19:16] = p_sum[2][19:16];
    assign g_sum[3][19:16] = g_sum[2][19:16];
    assign p_sum[3][15:12] = p_sum[2][15:12] & p_sum[2][11:8];
    assign g_sum[3][15:12] = g_sum[2][15:12] | (p_sum[2][15:12] & g_sum[2][11:8]);
    assign p_sum[3][11:8] = p_sum[2][11:8];
    assign g_sum[3][11:8] = g_sum[2][11:8];
    assign p_sum[3][7:4] = p_sum[2][7:4] & p_sum[2][3:0];
    assign g_sum[3][7:4] = g_sum[2][7:4] | (p_sum[2][7:4] & g_sum[2][3:0]);
    assign p_sum[3][3:0] = p_sum[2][3:0];
    assign g_sum[3][3:0] = g_sum[2][3:0];
    
    // Level 4 - Final level of prefix computation (bit by bit)
    genvar j;
    generate
        for (j = 0; j < 31; j = j + 1) begin : final_level
            assign p_sum[4][j+1] = p_sum[3][j+1] & p_sum[3][j];
            assign g_sum[4][j+1] = g_sum[3][j+1] | (p_sum[3][j+1] & g_sum[3][j]);
        end
    endgenerate
    assign p_sum[4][0] = p_sum[3][0];
    assign g_sum[4][0] = g_sum[3][0];
    
    // Final sum computation
    assign new_count = current_count + increment - ~g_sum[4] - 1'b1;
    
    // Stage 3: Final output and traffic accumulation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_stage3 <= {(N*DW){1'b0}};
            valid_stage3 <= 1'b0;
            traffic_count_reg <= 32'd0;
        end else begin
            dout_stage3 <= dout_stage2;
            valid_stage3 <= valid_stage2;
            
            // Update traffic count using parallel prefix adder result
            if (valid_stage2) begin
                traffic_count_reg <= new_count;
            end
        end
    end
    
    // Connect outputs
    assign dout = dout_stage3;
    assign valid_out = valid_stage3;
    assign traffic_count = traffic_count_reg;
    
endmodule