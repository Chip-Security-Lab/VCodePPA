//SystemVerilog
module sync_signal_recovery (
    // Clock and Reset
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready
);

    // Internal signals and registers
    reg [7:0] clean_signal;
    reg valid_out;
    reg [7:0] noisy_signal;
    reg valid_in;
    
    // Register addresses
    localparam ADDR_NOISY_SIG  = 4'h0;  // Address for noisy_signal
    localparam ADDR_VALID_IN   = 4'h4;  // Address for valid_in
    localparam ADDR_CLEAN_SIG  = 4'h8;  // Address for clean_signal
    localparam ADDR_VALID_OUT  = 4'hC;  // Address for valid_out
    
    // AXI4-Lite write process
    reg awready_r;
    reg wready_r;
    reg [3:0] write_addr;
    reg write_valid;
    
    // AXI4-Lite read process
    reg arready_r;
    reg [3:0] read_addr;
    reg read_valid;
    
    // Clock buffer tree for high fanout signal
    reg clk_buf1, clk_buf2, clk_buf3, clk_buf4;
    
    always @(*) begin
        clk_buf1 = clk;
        clk_buf2 = clk;
        clk_buf3 = clk;
        clk_buf4 = clk;
    end
    
    // Reset buffer for high fanout
    reg rst_n_buf1, rst_n_buf2;
    
    always @(*) begin
        rst_n_buf1 = rst_n;
        rst_n_buf2 = rst_n;
    end

    // Write Address Channel FSM
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            s_axil_awready <= 1'b0;
            write_addr <= 4'h0;
            awready_r <= 1'b1;
        end else if (s_axil_awvalid && awready_r) begin
            write_addr <= s_axil_awaddr[3:0];
            s_axil_awready <= 1'b1;
            awready_r <= 1'b0;
        end else begin
            s_axil_awready <= 1'b0;
            if (!s_axil_awvalid && !wready_r)
                awready_r <= 1'b1;
        end
    end
    
    // Write Data Channel FSM
    always @(posedge clk_buf1 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            s_axil_wready <= 1'b0;
            write_valid <= 1'b0;
            wready_r <= 1'b1;
        end else if (s_axil_wvalid && wready_r) begin
            s_axil_wready <= 1'b1;
            write_valid <= 1'b1;
            wready_r <= 1'b0;
        end else begin
            s_axil_wready <= 1'b0;
            write_valid <= 1'b0;
            if (!s_axil_wvalid && !s_axil_bvalid)
                wready_r <= 1'b1;
        end
    end
    
    // Buffer for write_valid (high fanout signal)
    reg write_valid_buf1, write_valid_buf2;
    
    always @(posedge clk_buf2) begin
        write_valid_buf1 <= write_valid;
        write_valid_buf2 <= write_valid;
    end
    
    // Write Response Channel FSM
    always @(posedge clk_buf2 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;  // OKAY response
        end else if (write_valid_buf1 && !s_axil_bvalid) begin
            s_axil_bvalid <= 1'b1;
            s_axil_bresp <= 2'b00;  // OKAY response
        end else if (s_axil_bready && s_axil_bvalid) begin
            s_axil_bvalid <= 1'b0;
        end
    end
    
    // Register write process with buffered signals
    always @(posedge clk_buf2 or negedge rst_n_buf1) begin
        if (!rst_n_buf1) begin
            noisy_signal <= 8'h00;
            valid_in <= 1'b0;
        end else if (write_valid_buf2) begin
            case (write_addr)
                ADDR_NOISY_SIG: if (s_axil_wstrb[0]) noisy_signal <= s_axil_wdata[7:0];
                ADDR_VALID_IN: if (s_axil_wstrb[0]) valid_in <= s_axil_wdata[0];
                default: ; // No operation for other addresses
            endcase
        end
    end
    
    // Read Address Channel FSM
    always @(posedge clk_buf3 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            s_axil_arready <= 1'b0;
            read_addr <= 4'h0;
            arready_r <= 1'b1;
        end else if (s_axil_arvalid && arready_r) begin
            read_addr <= s_axil_araddr[3:0];
            s_axil_arready <= 1'b1;
            arready_r <= 1'b0;
            read_valid <= 1'b1;
        end else begin
            s_axil_arready <= 1'b0;
            read_valid <= 1'b0;
            if (!s_axil_arvalid && !s_axil_rvalid)
                arready_r <= 1'b1;
        end
    end
    
    // Read valid buffer for high fanout
    reg read_valid_buf;
    
    always @(posedge clk_buf3) begin
        read_valid_buf <= read_valid;
    end
    
    // Read Data Channel FSM
    always @(posedge clk_buf3 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'h0;
            s_axil_rresp <= 2'b00;  // OKAY response
        end else if (read_valid_buf && !s_axil_rvalid) begin
            s_axil_rvalid <= 1'b1;
            s_axil_rresp <= 2'b00;  // OKAY response
            
            case (read_addr)
                ADDR_NOISY_SIG: s_axil_rdata <= {24'h0, noisy_signal};
                ADDR_VALID_IN: s_axil_rdata <= {31'h0, valid_in};
                ADDR_CLEAN_SIG: s_axil_rdata <= {24'h0, clean_signal};
                ADDR_VALID_OUT: s_axil_rdata <= {31'h0, valid_out};
                default: s_axil_rdata <= 32'h0;
            endcase
        end else if (s_axil_rready && s_axil_rvalid) begin
            s_axil_rvalid <= 1'b0;
        end
    end
    
    // Buffer for valid_in (high fanout signal)
    reg valid_in_buf;
    
    always @(posedge clk_buf4) begin
        valid_in_buf <= valid_in;
    end
    
    // Core signal processing logic (unchanged functionality)
    always @(posedge clk_buf4 or negedge rst_n_buf2) begin
        if (!rst_n_buf2) begin
            clean_signal <= 8'b0;
            valid_out <= 1'b0;
        end else if (valid_in_buf) begin
            clean_signal <= noisy_signal;
            valid_out <= 1'b1;
        end else begin
            valid_out <= 1'b0;
        end
    end

endmodule