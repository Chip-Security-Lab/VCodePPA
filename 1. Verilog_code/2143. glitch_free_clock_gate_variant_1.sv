//SystemVerilog
module glitch_free_clock_gate (
    // Clock and Reset
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Clock output
    input  wire        clk_in,
    output wire        clk_out
);

    // Register map
    // 0x00: Control Register - bit[0]: enable bit
    
    // Internal signals
    reg enable;
    reg enable_ff1, enable_ff2;
    
    // Write address channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // Write data channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            enable <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awready) begin
                s_axi_wready <= 1'b1;
                
                // Write to control register
                if (s_axi_awaddr[7:0] == 8'h00 && s_axi_wstrb[0]) begin
                    enable <= s_axi_wdata[0];
                end
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end
    
    // Write response channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00; // OKAY
        end else begin
            if (s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // Read address channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end
    
    // Read data channel handling
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00; // OKAY
        end else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY
                
                // Read from control register
                if (s_axi_araddr[7:0] == 8'h00) begin
                    s_axi_rdata <= {31'b0, enable};
                end else begin
                    s_axi_rdata <= 32'h00000000;
                end
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    // Core clock gating logic
    always @(posedge clk_in or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            enable_ff1 <= 1'b0;
            enable_ff2 <= 1'b0;
        end else begin
            enable_ff1 <= enable;
            enable_ff2 <= enable_ff1;
        end
    end
    
    // Generate gated clock output
    assign clk_out = clk_in & enable_ff2;

endmodule