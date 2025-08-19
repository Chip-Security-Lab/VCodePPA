//SystemVerilog
// Top level module
module sync_rst_decoder #(
    parameter ADDR_WIDTH = 4
)(
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output wire s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output wire s_axil_wready,
    
    // Write Response Channel
    output wire [1:0] s_axil_bresp,
    output wire s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    
    // Read Data Channel
    output wire [31:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready,
    
    // Original module output
    output wire [15:0] select
);

    // Internal signals for connecting submodules
    wire [ADDR_WIDTH-1:0] addr_value;

    // AXI4-Lite write interface controller submodule
    axi_write_controller #(
        .ADDR_WIDTH(ADDR_WIDTH)
    ) write_ctrl_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axil_awaddr(s_axil_awaddr),
        .s_axil_awvalid(s_axil_awvalid),
        .s_axil_awready(s_axil_awready),
        .s_axil_wdata(s_axil_wdata),
        .s_axil_wstrb(s_axil_wstrb),
        .s_axil_wvalid(s_axil_wvalid),
        .s_axil_wready(s_axil_wready),
        .s_axil_bresp(s_axil_bresp),
        .s_axil_bvalid(s_axil_bvalid),
        .s_axil_bready(s_axil_bready),
        .addr_out(addr_value)
    );

    // AXI4-Lite read interface controller submodule
    axi_read_controller read_ctrl_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axil_araddr(s_axil_araddr),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata),
        .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_rready(s_axil_rready),
        .select_in(select)
    );

    // Decoder logic submodule
    address_decoder #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .SELECT_WIDTH(16)
    ) decoder_inst (
        .aclk(aclk),
        .aresetn(aresetn),
        .addr_in(addr_value),
        .select_out(select)
    );

endmodule

// AXI4-Lite Write Interface Controller
module axi_write_controller #(
    parameter ADDR_WIDTH = 4
)(
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Module output
    output reg [ADDR_WIDTH-1:0] addr_out
);

    // FSM states definition
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam RESP = 2'b11;
    
    // State registers
    reg [1:0] write_state, write_next;
    
    // State register update
    always @(posedge aclk) begin
        if (!aresetn)
            write_state <= IDLE;
        else
            write_state <= write_next;
    end
    
    // State machine and control logic
    always @(*) begin
        // Default assignments
        write_next = write_state;
        s_axil_awready = 1'b0;
        s_axil_wready = 1'b0;
        s_axil_bvalid = 1'b0;
        s_axil_bresp = 2'b00; // OKAY
        
        case (write_state)
            IDLE: begin
                if (s_axil_awvalid) begin
                    write_next = ADDR;
                    s_axil_awready = 1'b1;
                end
            end
            
            ADDR: begin
                if (s_axil_wvalid) begin
                    write_next = RESP;
                    s_axil_wready = 1'b1;
                end
            end
            
            RESP: begin
                s_axil_bvalid = 1'b1;
                if (s_axil_bready)
                    write_next = IDLE;
            end
            
            default: write_next = IDLE;
        endcase
    end
    
    // Address capture logic
    always @(posedge aclk) begin
        if (!aresetn)
            addr_out <= {ADDR_WIDTH{1'b0}};
        else if (write_state == ADDR && s_axil_wvalid)
            addr_out <= s_axil_wdata[ADDR_WIDTH-1:0];
    end

endmodule

// AXI4-Lite Read Interface Controller
module axi_read_controller (
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Module input
    input wire [15:0] select_in
);

    // FSM states definition
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    
    // State registers
    reg [1:0] read_state, read_next;
    
    // State register update
    always @(posedge aclk) begin
        if (!aresetn)
            read_state <= IDLE;
        else
            read_state <= read_next;
    end
    
    // State machine and control logic
    always @(*) begin
        // Default assignments
        read_next = read_state;
        s_axil_arready = 1'b0;
        s_axil_rvalid = 1'b0;
        s_axil_rresp = 2'b00; // OKAY
        s_axil_rdata = 32'h0;
        
        case (read_state)
            IDLE: begin
                if (s_axil_arvalid) begin
                    read_next = ADDR;
                    s_axil_arready = 1'b1;
                end
            end
            
            ADDR: begin
                read_next = DATA;
                s_axil_rvalid = 1'b1;
                s_axil_rdata = {16'h0, select_in}; // Return current select value
            end
            
            DATA: begin
                s_axil_rvalid = 1'b1;
                s_axil_rdata = {16'h0, select_in};
                if (s_axil_rready)
                    read_next = IDLE;
            end
            
            default: read_next = IDLE;
        endcase
    end

endmodule

// Address Decoder Module
module address_decoder #(
    parameter ADDR_WIDTH = 4,
    parameter SELECT_WIDTH = 16
)(
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // Module input/output
    input wire [ADDR_WIDTH-1:0] addr_in,
    output reg [SELECT_WIDTH-1:0] select_out
);

    // One-hot decoder logic
    always @(posedge aclk) begin
        if (!aresetn)
            select_out <= {SELECT_WIDTH{1'b0}};
        else
            select_out <= ({{(SELECT_WIDTH-1){1'b0}}, 1'b1} << addr_in);
    end

endmodule