//SystemVerilog
module key_encoder_axi4lite (
    // Global signals
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,
    
    // AXI4-Lite write address channel
    input  wire [31:0] s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,
    
    // AXI4-Lite write data channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,
    
    // AXI4-Lite write response channel
    output reg [1:0]   s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,
    
    // AXI4-Lite read address channel
    input  wire [31:0] s_axi_araddr,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,
    
    // AXI4-Lite read data channel
    output reg [31:0]  s_axi_rdata,
    output reg [1:0]   s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready,
    
    // Original key input (preserved for functionality)
    input  wire [15:0] keys
);

    // Register to store encoded value
    reg [3:0] encoded_value;
    
    // Key encoder logic (preserved from original)
    always @(*) begin
        if (keys[0]) begin
            encoded_value = 4'h0;
        end
        else if (keys[1]) begin
            encoded_value = 4'h1;
        end
        else if (keys[2]) begin
            encoded_value = 4'h2;
        end
        else if (keys[3]) begin
            encoded_value = 4'h3;
        end
        else if (keys[4]) begin
            encoded_value = 4'h4;
        end
        else if (keys[5]) begin
            encoded_value = 4'h5;
        end
        else if (keys[6]) begin
            encoded_value = 4'h6;
        end
        else if (keys[7]) begin
            encoded_value = 4'h7;
        end
        else if (keys[8]) begin
            encoded_value = 4'h8;
        end
        else if (keys[9]) begin
            encoded_value = 4'h9;
        end
        else if (keys[10]) begin
            encoded_value = 4'hA;
        end
        else if (keys[11]) begin
            encoded_value = 4'hB;
        end
        else if (keys[12]) begin
            encoded_value = 4'hC;
        end
        else if (keys[13]) begin
            encoded_value = 4'hD;
        end
        else if (keys[14]) begin
            encoded_value = 4'hE;
        end
        else if (keys[15]) begin
            encoded_value = 4'hF;
        end
        else begin
            encoded_value = 4'hF;
        end
    end
    
    // Memory map registers
    reg [15:0] key_status_reg;
    reg [3:0]  key_code_reg;
    
    // Register address parameters
    localparam KEY_STATUS_ADDR = 32'h0000_0000;  // Contains current key status
    localparam KEY_CODE_ADDR   = 32'h0000_0004;  // Contains encoded key value
    
    // AXI4-Lite write address channel FSM
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
        end else begin
            if (!s_axi_awready && s_axi_awvalid) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite write data channel FSM
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            key_status_reg <= 16'b0;
        end else begin
            if (!s_axi_wready && s_axi_wvalid && s_axi_awvalid) begin
                s_axi_wready <= 1'b1;
                
                // Handle write based on address
                case (s_axi_awaddr)
                    KEY_STATUS_ADDR: begin
                        if (s_axi_wstrb[0]) key_status_reg[7:0] <= s_axi_wdata[7:0];
                        if (s_axi_wstrb[1]) key_status_reg[15:8] <= s_axi_wdata[15:8];
                    end
                    // KEY_CODE_ADDR is read-only
                endcase
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite write response channel FSM
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
        end else begin
            if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid && !s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY response
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite read address channel FSM
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (!s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite read data channel FSM
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
        end else begin
            if (s_axi_arready && s_axi_arvalid && !s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY response
                
                // Provide read data based on address
                case (s_axi_araddr)
                    KEY_STATUS_ADDR: s_axi_rdata <= {16'b0, keys};
                    KEY_CODE_ADDR: s_axi_rdata <= {28'b0, encoded_value};
                    default: s_axi_rdata <= 32'h0000_0000;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    // Update key status and code registers for internal use
    always @(posedge s_axi_aclk) begin
        key_status_reg <= keys;
        key_code_reg <= encoded_value;
    end

endmodule