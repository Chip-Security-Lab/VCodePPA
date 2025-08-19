//SystemVerilog
//IEEE 1364-2005 Verilog
module prescaler_timer (
    // Global signals
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite interface
    // Write address channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write data channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read address channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Timer output
    output reg tick_out
);

    // Register offsets
    localparam PRESCALE_SEL_REG = 4'h0;
    localparam PERIOD_REG = 4'h4;
    localparam STATUS_REG = 4'h8;
    
    // Internal registers for configuration
    reg [3:0] prescale_sel;
    reg [15:0] period;
    
    // Timer implementation registers
    reg [15:0] prescale_count;
    reg [15:0] timer_count;
    reg tick_enable;
    
    wire [15:0] prescale_next;
    wire [15:0] timer_next;
    
    // Buffered high fanout signals
    reg [15:0] prescale_count_buf1, prescale_count_buf2;
    reg [15:0] timer_count_buf1, timer_count_buf2;
    reg [15:0] prescale_next_buf1, prescale_next_buf2;
    
    // AXI4-Lite interface state control
    reg [3:0] axi_write_state;
    reg [3:0] axi_read_state;
    reg [31:0] read_address;
    
    // AXI-Lite states
    localparam IDLE = 4'h0;
    localparam ADDR = 4'h1;
    localparam DATA = 4'h2;
    localparam RESP = 4'h3;
    
    // Buffer high fanout signals
    always @(posedge clk) begin
        prescale_count_buf1 <= prescale_count;
        prescale_count_buf2 <= prescale_count;
        timer_count_buf1 <= timer_count;
        timer_count_buf2 <= timer_count;
        prescale_next_buf1 <= prescale_next;
        prescale_next_buf2 <= prescale_next;
    end
    
    // Carry Lookahead Adder (CLA) for prescaler counter
    wire [15:0] p_cin;
    wire [15:0] p_g, p_p; // Generate and Propagate signals
    wire [16:0] p_c; // Carry signals (one extra for final carry-out)
    
    // Buffered p_g and p_p signals
    reg [7:0] p_g_buf1_low, p_g_buf1_high;
    reg [7:0] p_g_buf2_low, p_g_buf2_high;
    reg [7:0] p_p_buf1_low, p_p_buf1_high;
    reg [7:0] p_p_buf2_low, p_p_buf2_high;
    
    // Calculate Generate and Propagate
    assign p_g = prescale_count_buf1 & 16'h0001; // Generate if both bits are 1
    assign p_p = prescale_count_buf2 | 16'h0001; // Propagate if either bit is 1
    
    // Buffer high fanout p_g and p_p signals
    always @(posedge clk) begin
        p_g_buf1_low <= p_g[7:0];
        p_g_buf1_high <= p_g[15:8];
        p_g_buf2_low <= p_g[7:0];
        p_g_buf2_high <= p_g[15:8];
        
        p_p_buf1_low <= p_p[7:0];
        p_p_buf1_high <= p_p[15:8];
        p_p_buf2_low <= p_p[7:0];
        p_p_buf2_high <= p_p[15:8];
    end
    
    // Calculate carries using lookahead logic with buffered signals
    assign p_c[0] = 1'b0; // Initial carry-in is 0
    
    // First level carries with first buffer
    assign p_c[1] = p_g_buf1_low[0] | (p_p_buf1_low[0] & p_c[0]);
    assign p_c[2] = p_g_buf1_low[1] | (p_p_buf1_low[1] & p_c[1]);
    assign p_c[3] = p_g_buf1_low[2] | (p_p_buf1_low[2] & p_c[2]);
    assign p_c[4] = p_g_buf1_low[3] | (p_p_buf1_low[3] & p_c[3]);
    assign p_c[5] = p_g_buf1_low[4] | (p_p_buf1_low[4] & p_c[4]);
    assign p_c[6] = p_g_buf1_low[5] | (p_p_buf1_low[5] & p_c[5]);
    assign p_c[7] = p_g_buf1_low[6] | (p_p_buf1_low[6] & p_c[6]);
    assign p_c[8] = p_g_buf1_low[7] | (p_p_buf1_low[7] & p_c[7]);
    
    // Second level carries with second buffer
    assign p_c[9] = p_g_buf1_high[0] | (p_p_buf1_high[0] & p_c[8]);
    assign p_c[10] = p_g_buf1_high[1] | (p_p_buf1_high[1] & p_c[9]);
    assign p_c[11] = p_g_buf1_high[2] | (p_p_buf1_high[2] & p_c[10]);
    assign p_c[12] = p_g_buf1_high[3] | (p_p_buf1_high[3] & p_c[11]);
    assign p_c[13] = p_g_buf1_high[4] | (p_p_buf1_high[4] & p_c[12]);
    assign p_c[14] = p_g_buf1_high[5] | (p_p_buf1_high[5] & p_c[13]);
    assign p_c[15] = p_g_buf1_high[6] | (p_p_buf1_high[6] & p_c[14]);
    assign p_c[16] = p_g_buf1_high[7] | (p_p_buf1_high[7] & p_c[15]);
    
    // Sum calculation with buffered signals
    assign prescale_next = prescale_count_buf1 ^ 16'h0001 ^ p_c[15:0];
    
    // CLA for timer counter
    wire [15:0] t_g, t_p; // Generate and Propagate signals
    wire [16:0] t_c; // Carry signals (one extra for final carry-out)
    
    // Calculate Generate and Propagate
    assign t_g = timer_count_buf1 & 16'h0001; // Generate if both bits are 1
    assign t_p = timer_count_buf2 | 16'h0001; // Propagate if either bit is 1
    
    // Calculate carries using lookahead logic
    assign t_c[0] = 1'b0; // Initial carry-in is 0
    assign t_c[1] = t_g[0] | (t_p[0] & t_c[0]);
    assign t_c[2] = t_g[1] | (t_p[1] & t_c[1]);
    assign t_c[3] = t_g[2] | (t_p[2] & t_c[2]);
    assign t_c[4] = t_g[3] | (t_p[3] & t_c[3]);
    assign t_c[5] = t_g[4] | (t_p[4] & t_c[4]);
    assign t_c[6] = t_g[5] | (t_p[5] & t_c[5]);
    assign t_c[7] = t_g[6] | (t_p[6] & t_c[6]);
    assign t_c[8] = t_g[7] | (t_p[7] & t_c[7]);
    assign t_c[9] = t_g[8] | (t_p[8] & t_c[8]);
    assign t_c[10] = t_g[9] | (t_p[9] & t_c[9]);
    assign t_c[11] = t_g[10] | (t_p[10] & t_c[10]);
    assign t_c[12] = t_g[11] | (t_p[11] & t_c[11]);
    assign t_c[13] = t_g[12] | (t_p[12] & t_c[12]);
    assign t_c[14] = t_g[13] | (t_p[13] & t_c[13]);
    assign t_c[15] = t_g[14] | (t_p[14] & t_c[14]);
    assign t_c[16] = t_g[15] | (t_p[15] & t_c[15]);
    
    // Sum calculation
    assign timer_next = timer_count_buf1 ^ 16'h0001 ^ t_c[15:0];
    
    // AXI4-Lite Write Channel State Machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_write_state <= IDLE;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            prescale_sel <= 4'd0;
            period <= 16'd0;
        end else begin
            case (axi_write_state)
                IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b1;
                    s_axil_bvalid <= 1'b0;
                    if (s_axil_awvalid && s_axil_wvalid) begin
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b0;
                        // Process write
                        case (s_axil_awaddr[3:0])
                            PRESCALE_SEL_REG: begin
                                if (s_axil_wstrb[0]) 
                                    prescale_sel <= s_axil_wdata[3:0];
                                axi_write_state <= RESP;
                                s_axil_bresp <= 2'b00; // OKAY
                            end
                            PERIOD_REG: begin
                                if (s_axil_wstrb[0]) 
                                    period[7:0] <= s_axil_wdata[7:0];
                                if (s_axil_wstrb[1]) 
                                    period[15:8] <= s_axil_wdata[15:8];
                                axi_write_state <= RESP;
                                s_axil_bresp <= 2'b00; // OKAY
                            end
                            default: begin
                                axi_write_state <= RESP;
                                s_axil_bresp <= 2'b10; // SLVERR for unrecognized address
                            end
                        endcase
                    end
                end
                RESP: begin
                    s_axil_bvalid <= 1'b1;
                    if (s_axil_bready) begin
                        s_axil_bvalid <= 1'b0;
                        axi_write_state <= IDLE;
                        s_axil_awready <= 1'b1;
                        s_axil_wready <= 1'b1;
                    end
                end
                default: axi_write_state <= IDLE;
            endcase
        end
    end
    
    // AXI4-Lite Read Channel State Machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            axi_read_state <= IDLE;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
            read_address <= 32'h0;
        end else begin
            case (axi_read_state)
                IDLE: begin
                    s_axil_arready <= 1'b1;
                    if (s_axil_arvalid) begin
                        read_address <= s_axil_araddr;
                        s_axil_arready <= 1'b0;
                        axi_read_state <= RESP;
                    end
                end
                RESP: begin
                    s_axil_rvalid <= 1'b1;
                    case (read_address[3:0])
                        PRESCALE_SEL_REG: begin
                            s_axil_rdata <= {28'h0, prescale_sel};
                            s_axil_rresp <= 2'b00; // OKAY
                        end
                        PERIOD_REG: begin
                            s_axil_rdata <= {16'h0, period};
                            s_axil_rresp <= 2'b00; // OKAY
                        end
                        STATUS_REG: begin
                            s_axil_rdata <= {15'h0, tick_out, prescale_count, timer_count};
                            s_axil_rresp <= 2'b00; // OKAY
                        end
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= 2'b10; // SLVERR for unrecognized address
                        end
                    endcase
                    
                    if (s_axil_rready) begin
                        s_axil_rvalid <= 1'b0;
                        axi_read_state <= IDLE;
                    end
                end
                default: axi_read_state <= IDLE;
            endcase
        end
    end
    
    // Prescaler logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prescale_count <= 16'h0000;
            tick_enable <= 1'b0;
        end else begin
            case (prescale_sel)
                4'd0: tick_enable <= 1'b1;
                4'd1: begin
                    if (prescale_count >= 16'd1) begin
                        prescale_count <= 16'h0000;
                        tick_enable <= 1'b1;
                    end else begin
                        prescale_count <= prescale_next_buf1;
                        tick_enable <= 1'b0;
                    end
                end
                4'd2: begin
                    if (prescale_count >= 16'd3) begin
                        prescale_count <= 16'h0000;
                        tick_enable <= 1'b1;
                    end else begin
                        prescale_count <= prescale_next_buf1;
                        tick_enable <= 1'b0;
                    end
                end
                default: begin
                    if (prescale_count >= (16'd1 << prescale_sel) - 1) begin
                        prescale_count <= 16'h0000;
                        tick_enable <= 1'b1;
                    end else begin
                        prescale_count <= prescale_next_buf2;
                        tick_enable <= 1'b0;
                    end
                end
            endcase
        end
    end
    
    // Timer logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_count <= 16'h0000;
            tick_out <= 1'b0;
        end else if (tick_enable) begin
            if (timer_count >= period - 1) begin
                timer_count <= 16'h0000;
                tick_out <= 1'b1;
            end else begin
                timer_count <= timer_next;
                tick_out <= 1'b0;
            end
        end
    end
endmodule