//SystemVerilog
//IEEE 1364-2005 SystemVerilog
module bidir_demux_axi (
    // AXI4-Lite Slave Interface
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    // Write Address Channel
    input  wire [7:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    // Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    // Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    // Read Address Channel
    input  wire [7:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    // Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Original bidirectional ports
    inout  wire        common_io,
    inout  wire [3:0]  channel_io
);

    // Internal control registers
    reg [1:0] channel_sel;
    reg       direction;
    reg [31:0] status_reg;
    
    // AXI4-Lite write FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    reg [1:0] write_state;
    
    // AXI4-Lite read FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    reg [1:0] read_state;
    
    // Register addresses
    localparam CTRL_REG_ADDR   = 8'h00; // Control register: [0]=direction, [2:1]=channel_sel
    localparam STATUS_REG_ADDR = 8'h04; // Status register
    
    // Write address capture
    reg [7:0] axi_awaddr_reg;
    
    //--------------------------------------------------
    // AXI4-Lite Write Channel State Machine
    //--------------------------------------------------
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            write_state <= WRITE_IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            axi_awaddr_reg <= 8'h00;
        end
        else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axi_awready <= 1'b1;
                    s_axi_wready <= 1'b1;
                    
                    if (s_axi_awready && s_axi_awvalid) begin
                        axi_awaddr_reg <= s_axi_awaddr;
                        s_axi_awready <= 1'b0;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    if (s_axi_wready && s_axi_wvalid) begin
                        s_axi_wready <= 1'b0;
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axi_bvalid && s_axi_bready) begin
                        write_state <= WRITE_IDLE;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
        end
    end
    
    //--------------------------------------------------
    // AXI4-Lite Write Data Handler
    //--------------------------------------------------
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            // Reset control registers
            channel_sel <= 2'b00;
            direction <= 1'b0;
        end
        else if (write_state == WRITE_ADDR && s_axi_wready && s_axi_wvalid) begin
            // Write to appropriate register based on address
            if (axi_awaddr_reg == CTRL_REG_ADDR) begin
                direction <= s_axi_wdata[0];
                channel_sel <= s_axi_wdata[2:1];
            end
        end
    end
    
    //--------------------------------------------------
    // AXI4-Lite Write Response Channel Handler
    //--------------------------------------------------
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00; // OKAY
        end
        else if (write_state == WRITE_ADDR && s_axi_wready && s_axi_wvalid) begin
            s_axi_bvalid <= 1'b1;
            s_axi_bresp <= 2'b00; // OKAY
        end
        else if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
        end
    end
    
    //--------------------------------------------------
    // AXI4-Lite Read Channel State Machine
    //--------------------------------------------------
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            read_state <= READ_IDLE;
            s_axi_arready <= 1'b0;
        end
        else begin
            case (read_state)
                READ_IDLE: begin
                    s_axi_arready <= 1'b1;
                    
                    if (s_axi_arready && s_axi_arvalid) begin
                        s_axi_arready <= 1'b0;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axi_rvalid && s_axi_rready) begin
                        read_state <= READ_IDLE;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end
    
    //--------------------------------------------------
    // AXI4-Lite Read Data Channel Handler
    //--------------------------------------------------
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00; // OKAY
            s_axi_rdata <= 32'h00000000;
        end
        else if (read_state == READ_ADDR) begin
            s_axi_rvalid <= 1'b1;
            s_axi_rresp <= 2'b00;
            
            // Set read data based on address
            case (s_axi_araddr)
                CTRL_REG_ADDR: begin
                    s_axi_rdata <= {29'b0, channel_sel, direction};
                end
                STATUS_REG_ADDR: begin
                    s_axi_rdata <= status_reg;
                end
                default: begin
                    s_axi_rdata <= 32'h00000000;
                end
            endcase
        end
        else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end
    
    //--------------------------------------------------
    // Status Register Update
    //--------------------------------------------------
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            status_reg <= 32'h00000000;
        end
        else begin
            // Update status register with IO values
            status_reg[0] <= common_io;
            status_reg[4:1] <= channel_io;
        end
    end
    
    //--------------------------------------------------
    // Bidirectional Demux Logic
    //--------------------------------------------------
    // Common to Channel routing (direction = 0)
    assign channel_io[0] = (!direction && channel_sel == 2'b00) ? common_io : 1'bz;
    assign channel_io[1] = (!direction && channel_sel == 2'b01) ? common_io : 1'bz;
    assign channel_io[2] = (!direction && channel_sel == 2'b10) ? common_io : 1'bz;
    assign channel_io[3] = (!direction && channel_sel == 2'b11) ? common_io : 1'bz;
    
    // Channel to Common routing (direction = 1)
    assign common_io = direction ? channel_io[channel_sel] : 1'bz;

endmodule