//SystemVerilog
module can_encoder_axi4lite (
    // Clock and Reset
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // CAN TX Output
    output wire        can_tx
);

    // Register address offsets
    localparam ADDR_CTRL     = 4'h0;  // Control register
    localparam ADDR_ID       = 4'h4;  // ID register
    localparam ADDR_DATA     = 4'h8;  // Data register
    localparam ADDR_STATUS   = 4'hC;  // Status register

    // Register definitions
    reg [31:0] ctrl_reg;     // [0] - tx_req
    reg [31:0] id_reg;       // [10:0] - CAN ID
    reg [31:0] data_reg;     // [7:0] - CAN data
    reg [31:0] status_reg;   // [0] - tx_ack

    // Internal signals for CAN encoder
    reg        tx_req;
    reg [10:0] id;
    reg [7:0]  data;
    reg        tx;
    wire       tx_ack;

    // AXI4-Lite interface signals
    reg        axi_awready;
    reg        axi_wready;
    reg        axi_bvalid;
    reg [1:0]  axi_bresp;
    reg        axi_arready;
    reg [31:0] axi_rdata;
    reg        axi_rvalid;
    reg [1:0]  axi_rresp;

    // Write address handshake
    reg [3:0]  write_addr;
    reg        write_addr_valid;

    // Read address handshake
    reg [3:0]  read_addr;
    reg        read_addr_valid;

    // CAN encoder state machine
    reg [14:0] crc;
    reg [3:0]  state;
    reg [3:0]  bit_counter;

    // AXI4-Lite Write Address Channel
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_awready <= 1'b0;
            write_addr <= 4'h0;
            write_addr_valid <= 1'b0;
        end else begin
            if (~axi_awready && s_axi_awvalid) begin
                axi_awready <= 1'b1;
                write_addr <= s_axi_awaddr[5:2];
                write_addr_valid <= 1'b1;
            end else begin
                axi_awready <= 1'b0;
                if (axi_wready && s_axi_wvalid) begin
                    write_addr_valid <= 1'b0;
                end
            end
        end
    end

    // AXI4-Lite Write Data Channel
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_wready <= 1'b0;
            ctrl_reg <= 32'h0;
            id_reg <= 32'h0;
            data_reg <= 32'h0;
        end else begin
            if (~axi_wready && s_axi_wvalid && write_addr_valid) begin
                axi_wready <= 1'b1;
                
                case (write_addr)
                    ADDR_CTRL: begin
                        if (s_axi_wstrb[0]) ctrl_reg[7:0] <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) ctrl_reg[15:8] <= s_axi_wdata[15:8];
                        if (s_axi_wstrb[2]) ctrl_reg[23:16] <= s_axi_wdata[23:16];
                        if (s_axi_wstrb[3]) ctrl_reg[31:24] <= s_axi_wdata[31:24];
                    end
                    ADDR_ID: begin
                        if (s_axi_wstrb[0]) id_reg[7:0] <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) id_reg[15:8] <= s_axi_wdata[15:8];
                        if (s_axi_wstrb[2]) id_reg[23:16] <= s_axi_wdata[23:16];
                        if (s_axi_wstrb[3]) id_reg[31:24] <= s_axi_wdata[31:24];
                    end
                    ADDR_DATA: begin
                        if (s_axi_wstrb[0]) data_reg[7:0] <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) data_reg[15:8] <= s_axi_wdata[15:8];
                        if (s_axi_wstrb[2]) data_reg[23:16] <= s_axi_wdata[23:16];
                        if (s_axi_wstrb[3]) data_reg[31:24] <= s_axi_wdata[31:24];
                    end
                    default: begin
                        // No write to read-only registers
                    end
                endcase
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // AXI4-Lite Write Response Channel
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_bvalid <= 1'b0;
            axi_bresp <= 2'b0;
        end else begin
            if (axi_wready && s_axi_wvalid && ~axi_bvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp <= 2'b00; // OKAY response
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // AXI4-Lite Read Address Channel
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_arready <= 1'b0;
            read_addr <= 4'h0;
            read_addr_valid <= 1'b0;
        end else begin
            if (~axi_arready && s_axi_arvalid && ~read_addr_valid) begin
                axi_arready <= 1'b1;
                read_addr <= s_axi_araddr[5:2];
                read_addr_valid <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
                if (axi_rvalid && s_axi_rready) begin
                    read_addr_valid <= 1'b0;
                end
            end
        end
    end

    // Update status register with tx_ack
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            status_reg <= 32'h0;
        end else begin
            status_reg[0] <= tx_ack;
        end
    end

    // AXI4-Lite Read Data Channel
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            axi_rvalid <= 1'b0;
            axi_rdata <= 32'h0;
            axi_rresp <= 2'b0;
        end else begin
            if (read_addr_valid && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp <= 2'b00;  // OKAY response
                
                case (read_addr)
                    ADDR_CTRL:    axi_rdata <= ctrl_reg;
                    ADDR_ID:      axi_rdata <= id_reg;
                    ADDR_DATA:    axi_rdata <= data_reg;
                    ADDR_STATUS:  axi_rdata <= status_reg;
                    default:      axi_rdata <= 32'h0;
                endcase
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Connect internal signals to the CAN encoder
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            tx_req <= 1'b0;
            id <= 11'h0;
            data <= 8'h0;
        end else begin
            tx_req <= ctrl_reg[0];
            id <= id_reg[10:0];
            data <= data_reg[7:0];
        end
    end

    // CAN Encoder state machine (original functionality preserved)
    always @(posedge s_axi_aclk) begin
        if (~s_axi_aresetn) begin
            tx <= 1'b1;  // Idle state is high
            crc <= 15'h0;
            state <= 4'd0;
            bit_counter <= 4'd0;
        end else begin
            case(state)
                4'd0: begin
                    if(tx_req) begin
                        tx <= 1'b0; // Start bit
                        crc <= 15'h7FF;
                        state <= 4'd1;
                        bit_counter <= 4'd0;
                    end else begin
                        tx <= 1'b1;  // Idle state
                    end
                end
                4'd1: begin // ID transmission
                    tx <= id[10 - bit_counter];
                    
                    // CRC calculation
                    if(crc[14] ^ tx) begin
                        crc <= (crc << 1) ^ 15'h4599;
                    end else begin
                        crc <= (crc << 1);
                    end
                    
                    if(bit_counter == 4'd10) begin
                        state <= 4'd2;
                        bit_counter <= 4'd0;
                    end else begin
                        bit_counter <= bit_counter + 4'd1;
                    end
                end
                4'd2: begin // RTR bit
                    tx <= 1'b0; // Data frame
                    
                    // CRC calculation
                    if(crc[14] ^ tx) begin
                        crc <= (crc << 1) ^ 15'h4599;
                    end else begin
                        crc <= (crc << 1);
                    end
                    
                    state <= 4'd3;
                    bit_counter <= 4'd0;
                end
                4'd3: begin // Data length
                    tx <= (bit_counter < 4) ? 1'b0 : 1'b1;
                    
                    // CRC calculation
                    if(crc[14] ^ tx) begin
                        crc <= (crc << 1) ^ 15'h4599;
                    end else begin
                        crc <= (crc << 1);
                    end
                    
                    if(bit_counter == 4'd3) begin
                        state <= 4'd4;
                        bit_counter <= 4'd0;
                    end else begin
                        bit_counter <= bit_counter + 4'd1;
                    end
                end
                4'd4: begin // Send data
                    tx <= data[7 - bit_counter];
                    
                    // CRC calculation
                    if(crc[14] ^ tx) begin
                        crc <= (crc << 1) ^ 15'h4599;
                    end else begin
                        crc <= (crc << 1);
                    end
                    
                    if(bit_counter == 4'd7) begin
                        state <= 4'd5;
                        bit_counter <= 4'd0;
                    end else begin
                        bit_counter <= bit_counter + 4'd1;
                    end
                end
                4'd5: begin // Send CRC
                    tx <= crc[14 - bit_counter];
                    
                    if(bit_counter == 4'd14) begin
                        state <= 4'd0;
                    end else begin
                        bit_counter <= bit_counter + 4'd1;
                    end
                end
                default: state <= 4'd0;
            endcase
        end
    end
    
    // Connect outputs
    assign tx_ack = (state == 4'd0);
    
    // AXI4-Lite interface outputs
    assign s_axi_awready = axi_awready;
    assign s_axi_wready = axi_wready;
    assign s_axi_bresp = axi_bresp;
    assign s_axi_bvalid = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata = axi_rdata;
    assign s_axi_rresp = axi_rresp;
    assign s_axi_rvalid = axi_rvalid;
    
    // CAN TX output
    assign can_tx = tx;

endmodule