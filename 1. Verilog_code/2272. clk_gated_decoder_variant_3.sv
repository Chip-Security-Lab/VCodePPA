//SystemVerilog
module clk_gated_decoder(
    input wire aclk,                   // AXI clock signal
    input wire aresetn,                // AXI reset signal (active low)
    
    // AXI4-Lite slave interface - Write Address Channel
    input wire [31:0] s_axil_awaddr,   // Write address
    input wire s_axil_awvalid,         // Write address valid
    output wire s_axil_awready,        // Write address ready
    
    // AXI4-Lite slave interface - Write Data Channel
    input wire [31:0] s_axil_wdata,    // Write data
    input wire [3:0] s_axil_wstrb,     // Write strobes
    input wire s_axil_wvalid,          // Write valid
    output wire s_axil_wready,         // Write ready
    
    // AXI4-Lite slave interface - Write Response Channel
    output wire [1:0] s_axil_bresp,    // Write response
    output wire s_axil_bvalid,         // Write response valid
    input wire s_axil_bready,          // Write response ready
    
    // AXI4-Lite slave interface - Read Address Channel
    input wire [31:0] s_axil_araddr,   // Read address
    input wire s_axil_arvalid,         // Read address valid
    output wire s_axil_arready,        // Read address ready
    
    // AXI4-Lite slave interface - Read Data Channel
    output wire [31:0] s_axil_rdata,   // Read data
    output wire [1:0] s_axil_rresp,    // Read response
    output wire s_axil_rvalid,         // Read valid
    input wire s_axil_rready,          // Read ready
    
    // Original output
    output wire [7:0] select
);

    // Internal signals between modules
    wire [2:0] addr_reg;
    wire enable_reg;
    wire [7:0] decoded_value;

    // AXI4-Lite interface handling
    axi_lite_slave #(
        .ADDR_CONTROL(4'h0)
    ) u_axi_slave (
        .aclk(aclk),
        .aresetn(aresetn),
        // Write channels
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
        // Read channels
        .s_axil_araddr(s_axil_araddr),
        .s_axil_arvalid(s_axil_arvalid),
        .s_axil_arready(s_axil_arready),
        .s_axil_rdata(s_axil_rdata),
        .s_axil_rresp(s_axil_rresp),
        .s_axil_rvalid(s_axil_rvalid),
        .s_axil_rready(s_axil_rready),
        // Control outputs
        .addr_reg(addr_reg),
        .enable_reg(enable_reg)
    );

    // Decoder logic
    decoder_core u_decoder_core (
        .addr_reg(addr_reg),
        .decoded_value(decoded_value)
    );

    // Output register control
    output_controller u_output_controller (
        .aclk(aclk),
        .aresetn(aresetn),
        .enable_reg(enable_reg),
        .decoded_value(decoded_value),
        .select(select)
    );

endmodule

//----------------------------------------------------------------------
// AXI Lite Slave Interface Module
//----------------------------------------------------------------------
module axi_lite_slave #(
    parameter ADDR_CONTROL = 4'h0    // Control register address
)(
    input wire aclk,
    input wire aresetn,
    
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
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
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Control outputs
    output reg [2:0] addr_reg,
    output reg enable_reg
);

    // AXI4-Lite response codes
    localparam RESP_OKAY = 2'b00;    // Normal access success
    localparam RESP_ERROR = 2'b10;   // Slave error
    
    // Internal state signals
    reg write_in_progress, read_in_progress;

    // Write channel FSM
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= RESP_OKAY;
            write_in_progress <= 1'b0;
            addr_reg <= 3'b000;
            enable_reg <= 1'b0;
        end else begin
            // Default values
            if (s_axil_bvalid && s_axil_bready)
                s_axil_bvalid <= 1'b0;
                
            if (!write_in_progress) begin
                if (s_axil_awvalid && s_axil_wvalid) begin
                    // Both address and data are valid
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b1;
                    write_in_progress <= 1'b1;
                    
                    // Check the address for validity
                    if (s_axil_awaddr[3:0] == ADDR_CONTROL) begin
                        // Valid control register access
                        addr_reg <= s_axil_wdata[2:0];
                        enable_reg <= s_axil_wdata[8];
                        s_axil_bresp <= RESP_OKAY;
                    end else begin
                        // Invalid address
                        s_axil_bresp <= RESP_ERROR;
                    end
                end
            end else begin
                // Complete the write transaction
                s_axil_awready <= 1'b0;
                s_axil_wready <= 1'b0;
                s_axil_bvalid <= 1'b1;
                write_in_progress <= 1'b0;
            end
        end
    end
    
    // Read channel FSM
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= RESP_OKAY;
            s_axil_rdata <= 32'h00000000;
            read_in_progress <= 1'b0;
        end else begin
            // Default values
            if (s_axil_rvalid && s_axil_rready)
                s_axil_rvalid <= 1'b0;
                
            if (!read_in_progress) begin
                if (s_axil_arvalid) begin
                    // Address is valid
                    s_axil_arready <= 1'b1;
                    read_in_progress <= 1'b1;
                    
                    // Check the address for validity
                    if (s_axil_araddr[3:0] == ADDR_CONTROL) begin
                        // Valid control register access
                        s_axil_rdata <= {23'b0, enable_reg, 5'b0, addr_reg};
                        s_axil_rresp <= RESP_OKAY;
                    end else begin
                        // Invalid address
                        s_axil_rdata <= 32'h00000000;
                        s_axil_rresp <= RESP_ERROR;
                    end
                end
            end else begin
                // Complete the read transaction
                s_axil_arready <= 1'b0;
                s_axil_rvalid <= 1'b1;
                read_in_progress <= 1'b0;
            end
        end
    end

endmodule

//----------------------------------------------------------------------
// Decoder Core Module
//----------------------------------------------------------------------
module decoder_core (
    input wire [2:0] addr_reg,
    output wire [7:0] decoded_value
);

    // One-hot decoder implementation (combinational)
    assign decoded_value = 8'b00000001 << addr_reg;

endmodule

//----------------------------------------------------------------------
// Output Controller Module
//----------------------------------------------------------------------
module output_controller (
    input wire aclk,
    input wire aresetn,
    input wire enable_reg,
    input wire [7:0] decoded_value,
    output reg [7:0] select
);

    // Output register control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            select <= 8'b00000000;
        end else if (enable_reg) begin
            select <= decoded_value;
        end
    end

endmodule