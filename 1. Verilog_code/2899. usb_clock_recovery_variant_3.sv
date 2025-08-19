//SystemVerilog
//IEEE 1364-2005 Verilog
module usb_clock_recovery (
    // AXI4-Lite slave interface
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // Write address channel
    input  wire [7:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    // Write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    // Write response channel
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    // Read address channel
    input  wire [7:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    // Read data channel
    output reg  [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // USB interface
    input  wire        dp_in,
    input  wire        dm_in
);

    // AXI4-Lite signals
    reg        awready;
    reg        wready;
    reg        bvalid;
    reg        arready;
    reg        rvalid;
    reg [1:0]  bresp;
    reg [1:0]  rresp;
    
    // Core registers
    reg        recovered_clk;
    reg        bit_locked;
    reg [2:0]  edge_detect;
    reg [7:0]  edge_counter;
    reg [7:0]  period_count;
    
    // Register addresses
    localparam REG_STATUS       = 8'h00;  // [0] = recovered_clk, [1] = bit_locked
    localparam REG_EDGE_COUNT   = 8'h04;  // Edge counter value
    localparam REG_PERIOD_COUNT = 8'h08;  // Period count value
    
    // Write address channel handling
    assign s_axi_awready = awready;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            awready <= 1'b1;
        end else begin
            if (s_axi_awvalid && awready) begin
                awready <= 1'b0;
            end else if (wready && s_axi_wvalid) begin
                awready <= 1'b1;
            end
        end
    end
    
    // Write data channel handling
    assign s_axi_wready = wready;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            wready <= 1'b1;
        end else begin
            if (s_axi_wvalid && wready) begin
                wready <= 1'b0;
            end else if (!wready && bvalid && s_axi_bready) begin
                wready <= 1'b1;
            end
        end
    end
    
    // Write response channel handling
    assign s_axi_bvalid = bvalid;
    assign s_axi_bresp = bresp;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            bvalid <= 1'b0;
            bresp <= 2'b00;  // OKAY response
        end else begin
            if (s_axi_wvalid && wready) begin
                bvalid <= 1'b1;
                bresp <= 2'b00;  // OKAY response
            end else if (bvalid && s_axi_bready) begin
                bvalid <= 1'b0;
            end
        end
    end
    
    // Read address channel handling
    assign s_axi_arready = arready;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            arready <= 1'b1;
        end else begin
            if (s_axi_arvalid && arready) begin
                arready <= 1'b0;
            end else if (rvalid && s_axi_rready) begin
                arready <= 1'b1;
            end
        end
    end
    
    // Read data channel handling
    assign s_axi_rvalid = rvalid;
    assign s_axi_rresp = rresp;
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            rvalid <= 1'b0;
            rresp <= 2'b00;  // OKAY response
        end else begin
            if (s_axi_arvalid && arready) begin
                rvalid <= 1'b1;
                rresp <= 2'b00;  // OKAY response
                
                // Read mux
                case (s_axi_araddr[7:0])
                    REG_STATUS: begin
                        s_axi_rdata <= {30'b0, bit_locked, recovered_clk};
                    end
                    REG_EDGE_COUNT: begin
                        s_axi_rdata <= {24'b0, edge_counter};
                    end
                    REG_PERIOD_COUNT: begin
                        s_axi_rdata <= {24'b0, period_count};
                    end
                    default: begin
                        s_axi_rdata <= 32'h00000000;
                    end
                endcase
            end else if (rvalid && s_axi_rready) begin
                rvalid <= 1'b0;
            end
        end
    end
    
    // Core USB clock recovery logic with parallel prefix adder
    wire [7:0] next_edge_counter, next_period_count;
    
    // Parallel prefix adder for edge_counter increment
    parallel_prefix_adder #(
        .WIDTH(8)
    ) edge_counter_adder (
        .a(edge_counter),
        .b(8'd1),
        .cin(1'b0),
        .sum(next_edge_counter)
    );
    
    // Parallel prefix adder for period_count increment
    parallel_prefix_adder #(
        .WIDTH(8)
    ) period_count_adder (
        .a(period_count),
        .b(8'd1),
        .cin(1'b0),
        .sum(next_period_count)
    );
    
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            edge_detect <= 3'b000;
            edge_counter <= 8'd0;
            period_count <= 8'd0;
            recovered_clk <= 1'b0;
            bit_locked <= 1'b0;
        end else begin
            edge_detect <= {edge_detect[1:0], dp_in ^ dm_in};
            
            if (edge_detect[2:1] == 2'b01) begin  // Rising edge
                edge_counter <= next_edge_counter;
                if (period_count > 8'd10) begin
                    bit_locked <= 1'b1;
                    period_count <= 8'd0;
                    recovered_clk <= 1'b1;
                end else begin
                    period_count <= next_period_count;
                end
            end else begin
                period_count <= next_period_count;
                if (period_count >= 8'd24) begin
                    recovered_clk <= 1'b0;
                    period_count <= 8'd0;
                end
            end
        end
    end

endmodule

// Parallel Prefix Adder (Kogge-Stone)
module parallel_prefix_adder #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] a,
    input wire [WIDTH-1:0] b,
    input wire cin,
    output wire [WIDTH-1:0] sum
);
    // Generate (g) and Propagate (p) signals
    wire [WIDTH-1:0] g, p;
    wire [WIDTH-1:0] g_next [WIDTH-1:0];
    wire [WIDTH-1:0] p_next [WIDTH-1:0];
    
    genvar i, j, k;
    
    // Initial g and p generation
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : gen_gp
            assign g[i] = a[i] & b[i];
            assign p[i] = a[i] | b[i];
        end
    endgenerate
    
    // First level of prefix tree with carry-in
    assign g_next[0][0] = g[0] | (p[0] & cin);
    assign p_next[0][0] = p[0];
    
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : first_level
            assign g_next[0][i] = g[i];
            assign p_next[0][i] = p[i];
        end
    endgenerate
    
    // Kogge-Stone parallel prefix tree
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : prefix_levels
            for (j = 0; j < WIDTH; j = j + 1) begin : prefix_cells
                if (j >= i) begin
                    assign g_next[i][j] = g_next[i-1][j] | (p_next[i-1][j] & g_next[i-1][j-i]);
                    assign p_next[i][j] = p_next[i-1][j] & p_next[i-1][j-i];
                end else begin
                    assign g_next[i][j] = g_next[i-1][j];
                    assign p_next[i][j] = p_next[i-1][j];
                end
            end
        end
    endgenerate
    
    // Calculate sum using final carry bits
    assign sum[0] = a[0] ^ b[0] ^ cin;
    
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : sum_calc
            assign sum[i] = a[i] ^ b[i] ^ g_next[WIDTH-1][i-1];
        end
    endgenerate
    
endmodule