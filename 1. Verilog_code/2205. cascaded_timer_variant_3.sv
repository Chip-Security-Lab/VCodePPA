//SystemVerilog
module cascaded_timer_axi4lite #(
    parameter C_S_AXI_DATA_WIDTH = 32,
    parameter C_S_AXI_ADDR_WIDTH = 4
) (
    // AXI4-Lite interface signals
    input  wire                          s_axi_aclk,
    input  wire                          s_axi_aresetn,
    // Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                          s_axi_awvalid,
    output wire                          s_axi_awready,
    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [C_S_AXI_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  wire                          s_axi_wvalid,
    output wire                          s_axi_wready,
    // Write Response Channel
    output wire [1:0]                    s_axi_bresp,
    output wire                          s_axi_bvalid,
    input  wire                          s_axi_bready,
    // Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                          s_axi_arvalid,
    output wire                          s_axi_arready,
    // Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output wire [1:0]                    s_axi_rresp,
    output wire                          s_axi_rvalid,
    input  wire                          s_axi_rready,
    
    // Timer outputs
    output wire                          timer1_tick_o,
    output wire                          timer2_tick_o
);

    // Register addresses - one-hot encoded for faster decoding
    localparam ADDR_CONTROL    = 0;  // Enable bit
    localparam ADDR_TIMER1_MAX = 1;  // Timer1 max value
    localparam ADDR_TIMER2_MAX = 2;  // Timer2 max value
    localparam ADDR_STATUS     = 3;  // Status register

    // Internal registers
    reg        enable_reg;
    reg [7:0]  timer1_max_reg;
    reg [7:0]  timer2_max_reg;
    reg [7:0]  timer1_count;
    reg [7:0]  timer2_count;
    reg        timer1_tick_r;
    reg        timer2_tick_r;
    
    // AXI interface registers
    reg                          axi_awready;
    reg                          axi_wready;
    reg                          axi_bvalid;
    reg                          axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg                          axi_rvalid;
    
    // Address storage registers
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    
    // Intermediate control signals - simplified condition structure
    wire aw_handshake_ready;
    wire write_transaction_start;
    wire write_transaction_complete;
    wire read_addr_handshake;
    wire read_data_handshake;
    
    // Address decoding with simplified structure
    reg [3:0] write_addr_decoded;
    reg [3:0] read_addr_decoded;
    
    // Timer control signals
    wire timer1_enable;
    wire timer1_should_increment;
    wire timer1_should_reset;
    wire timer2_enable;
    wire timer2_should_increment;
    wire timer2_should_reset;
    
    // AXI interface assignments
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = 2'b00; // OKAY response
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = 2'b00; // OKAY response
    assign s_axi_rvalid  = axi_rvalid;
    
    // Timer outputs
    assign timer1_tick_o = timer1_tick_r;
    assign timer2_tick_o = timer2_tick_r;
    
    // Simplified control signal generation
    assign aw_handshake_ready = ~axi_awready && s_axi_awvalid && s_axi_wvalid;
    assign write_transaction_start = axi_wready && s_axi_wvalid && axi_awready && s_axi_awvalid;
    assign write_transaction_complete = axi_bvalid && s_axi_bready;
    assign read_addr_handshake = ~axi_arready && s_axi_arvalid;
    assign read_data_handshake = axi_rvalid && s_axi_rready;
    
    // Timer control signals
    assign timer1_enable = enable_reg;
    assign timer1_should_increment = timer1_enable && (timer1_count != timer1_max_reg - 1'b1);
    assign timer1_should_reset = timer1_enable && (timer1_count == timer1_max_reg - 1'b1);
    assign timer2_enable = timer1_tick_r;
    assign timer2_should_increment = timer2_enable && (timer2_count != timer2_max_reg - 1'b1);
    assign timer2_should_reset = timer2_enable && (timer2_count == timer2_max_reg - 1'b1);
    
    // Address decoder - simplified with separate processes
    always @(*) begin
        write_addr_decoded = 4'b0000;
        case (axi_awaddr[3:2])
            2'b00: write_addr_decoded = 4'b0001;
            2'b01: write_addr_decoded = 4'b0010;
            2'b10: write_addr_decoded = 4'b0100;
            2'b11: write_addr_decoded = 4'b1000;
        endcase
    end
    
    always @(*) begin
        read_addr_decoded = 4'b0000;
        case (axi_araddr[3:2])
            2'b00: read_addr_decoded = 4'b0001;
            2'b01: read_addr_decoded = 4'b0010;
            2'b10: read_addr_decoded = 4'b0100;
            2'b11: read_addr_decoded = 4'b1000;
        endcase
    end
    
    // Write Address Channel - simplified flow
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 1'b0;
        end else begin
            if (aw_handshake_ready) begin
                axi_awready <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end
    
    // Write Data Channel - simplified flow
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_wready <= 1'b0;
            axi_awaddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (aw_handshake_ready) begin
                axi_wready <= 1'b1;
                axi_awaddr <= s_axi_awaddr;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end
    
    // Write Response Channel - simplified flow
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
        end else begin
            if (write_transaction_start) begin
                axi_bvalid <= 1'b1;
            end else if (write_transaction_complete) begin
                axi_bvalid <= 1'b0;
            end
        end
    end
    
    // Register write process - simplified logic
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            enable_reg     <= 1'b0;
            timer1_max_reg <= 8'd0;
            timer2_max_reg <= 8'd0;
        end else begin
            if (write_transaction_start) begin
                // Control register
                if (write_addr_decoded[ADDR_CONTROL] && s_axi_wstrb[0]) begin
                    enable_reg <= s_axi_wdata[0];
                end
                
                // Timer1 max register
                if (write_addr_decoded[ADDR_TIMER1_MAX] && s_axi_wstrb[0]) begin
                    timer1_max_reg <= s_axi_wdata[7:0];
                end
                
                // Timer2 max register
                if (write_addr_decoded[ADDR_TIMER2_MAX] && s_axi_wstrb[0]) begin
                    timer2_max_reg <= s_axi_wdata[7:0];
                end
            end
        end
    end
    
    // Read Address Channel - simplified flow
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_araddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (read_addr_handshake) begin
                axi_arready <= 1'b1;
                axi_araddr <= s_axi_araddr;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end
    
    // Read Data Channel - simplified flow
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rdata  <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end else begin
            if (axi_arready && s_axi_arvalid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                
                // Set data based on address
                if (read_addr_decoded[ADDR_CONTROL]) begin
                    axi_rdata <= {31'b0, enable_reg};
                end else if (read_addr_decoded[ADDR_TIMER1_MAX]) begin
                    axi_rdata <= {24'b0, timer1_max_reg};
                end else if (read_addr_decoded[ADDR_TIMER2_MAX]) begin
                    axi_rdata <= {24'b0, timer2_max_reg};
                end else if (read_addr_decoded[ADDR_STATUS]) begin
                    axi_rdata <= {22'b0, timer2_count, timer1_count};
                end else begin
                    axi_rdata <= 32'h00000000;
                end
            end else if (read_data_handshake) begin
                axi_rvalid <= 1'b0;
            end
        end
    end
    
    // Timer1 logic - simplified with intermediate signals
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            timer1_count <= 8'd0;
            timer1_tick_r <= 1'b0;
        end else begin
            // Default values
            timer1_tick_r <= 1'b0;
            
            if (timer1_enable) begin
                if (timer1_should_reset) begin
                    timer1_count <= 8'd0;
                    timer1_tick_r <= 1'b1;
                end else if (timer1_should_increment) begin
                    timer1_count <= timer1_count + 1'b1;
                end
            end
        end
    end
    
    // Timer2 logic - simplified with intermediate signals
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            timer2_count <= 8'd0;
            timer2_tick_r <= 1'b0;
        end else begin
            // Default values
            timer2_tick_r <= 1'b0;
            
            if (timer2_enable) begin
                if (timer2_should_reset) begin
                    timer2_count <= 8'd0;
                    timer2_tick_r <= 1'b1;
                end else if (timer2_should_increment) begin
                    timer2_count <= timer2_count + 1'b1;
                end
            end
        end
    end

endmodule