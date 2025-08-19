//SystemVerilog
module odd_div_biedge #(parameter N=5) (
    input clk, rst_n,
    output clk_out
);
    // Internal signals
    wire pos_edge_toggle;
    wire neg_edge_toggle;
    
    // Instantiate positive edge counter module
    pos_edge_counter #(.N(N)) pos_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .toggle_out(pos_edge_toggle)
    );
    
    // Instantiate negative edge counter module
    neg_edge_counter #(.N(N)) neg_counter_inst (
        .clk(clk),
        .rst_n(rst_n),
        .toggle_out(neg_edge_toggle)
    );
    
    // Combinational logic for output generation
    assign clk_out = pos_edge_toggle ^ neg_edge_toggle;
    
endmodule

// Positive edge counter module
module pos_edge_counter #(parameter N=5) (
    input clk, rst_n,
    output toggle_out
);
    // Sequential registers
    reg [2:0] cnt_r;
    reg toggle_r;
    
    // Combinational signals
    wire [2:0] cnt_next;
    wire toggle_next;
    
    // Parallel prefix subtractor signals
    wire [2:0] a, b, diff;
    wire [3:0] p, g;
    wire [3:0] P, G;
    
    // Input for subtractor
    assign a = cnt_r;
    assign b = (cnt_r == N-1) ? 3'd0 : 3'd1;
    
    // Generate propagate and generate signals
    assign p[0] = a[0] ^ ~b[0];
    assign p[1] = a[1] ^ ~b[1];
    assign p[2] = a[2] ^ ~b[2];
    assign p[3] = 1'b0;
    
    assign g[0] = a[0] & ~b[0];
    assign g[1] = a[1] & ~b[1];
    assign g[2] = a[2] & ~b[2];
    assign g[3] = 1'b0;
    
    // Parallel prefix computation
    assign P[0] = p[0];
    assign G[0] = g[0];
    
    assign P[1] = p[1] & P[0];
    assign G[1] = g[1] | (p[1] & G[0]);
    
    assign P[2] = p[2] & P[1];
    assign G[2] = g[2] | (p[2] & G[1]);
    
    assign P[3] = p[3] & P[2];
    assign G[3] = g[3] | (p[3] & G[2]);
    
    // Compute difference
    assign diff[0] = p[0] ^ 1'b1;
    assign diff[1] = p[1] ^ G[0];
    assign diff[2] = p[2] ^ G[1];
    
    // Determine next counter value
    assign cnt_next = (cnt_r == N-1) ? 3'd0 : diff;
    assign toggle_next = (cnt_r == N-1) ? ~toggle_r : toggle_r;
    
    // Sequential logic for registers update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_r <= 3'd0;
            toggle_r <= 1'b0;
        end else begin
            cnt_r <= cnt_next;
            toggle_r <= toggle_next;
        end
    end
    
    // Output assignment
    assign toggle_out = toggle_r;
    
endmodule

// Negative edge counter module
module neg_edge_counter #(parameter N=5) (
    input clk, rst_n,
    output toggle_out
);
    // Sequential registers
    reg [2:0] cnt_r;
    reg toggle_r;
    
    // Combinational signals
    wire [2:0] cnt_next;
    wire toggle_next;
    
    // Parallel prefix subtractor signals
    wire [2:0] a, b, diff;
    wire [3:0] p, g;
    wire [3:0] P, G;
    
    // Input for subtractor
    assign a = cnt_r;
    assign b = (cnt_r == N-1) ? 3'd0 : 3'd1;
    
    // Generate propagate and generate signals
    assign p[0] = a[0] ^ ~b[0];
    assign p[1] = a[1] ^ ~b[1];
    assign p[2] = a[2] ^ ~b[2];
    assign p[3] = 1'b0;
    
    assign g[0] = a[0] & ~b[0];
    assign g[1] = a[1] & ~b[1];
    assign g[2] = a[2] & ~b[2];
    assign g[3] = 1'b0;
    
    // Parallel prefix computation
    assign P[0] = p[0];
    assign G[0] = g[0];
    
    assign P[1] = p[1] & P[0];
    assign G[1] = g[1] | (p[1] & G[0]);
    
    assign P[2] = p[2] & P[1];
    assign G[2] = g[2] | (p[2] & G[1]);
    
    assign P[3] = p[3] & P[2];
    assign G[3] = g[3] | (p[3] & G[2]);
    
    // Compute difference
    assign diff[0] = p[0] ^ 1'b1;
    assign diff[1] = p[1] ^ G[0];
    assign diff[2] = p[2] ^ G[1];
    
    // Determine next counter value
    assign cnt_next = (cnt_r == N-1) ? 3'd0 : diff;
    assign toggle_next = (cnt_r == N-1) ? ~toggle_r : toggle_r;
    
    // Sequential logic for registers update
    always @(negedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_r <= 3'd0;
            toggle_r <= 1'b0;
        end else begin
            cnt_r <= cnt_next;
            toggle_r <= toggle_next;
        end
    end
    
    // Output assignment
    assign toggle_out = toggle_r;
    
endmodule