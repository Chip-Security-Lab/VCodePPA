//SystemVerilog
module vending_machine_axi_lite (
    // Clock and reset
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
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Interrupt output
    output reg dispense
);

    // Register map
    localparam ADDR_STATE = 4'h0;
    localparam ADDR_CONTROL = 4'h4;
    localparam ADDR_STATUS = 4'h8;
    
    // Internal registers
    reg [4:0] state, next_state;
    reg [1:0] coin;
    reg [31:0] control_reg;
    reg [31:0] status_reg;
    
    // AXI4-Lite state machine
    reg [2:0] axi_state;
    localparam IDLE = 3'd0;
    localparam WRITE_ADDR = 3'd1;
    localparam WRITE_DATA = 3'd2;
    localparam WRITE_RESP = 3'd3;
    localparam READ_ADDR = 3'd4;
    localparam READ_DATA = 3'd5;
    
    // Karatsuba multiplier for 5-bit multiplication
    function [4:0] karatsuba_mult;
        input [4:0] a, b;
        reg [2:0] a_high, a_low, b_high, b_low;
        reg [4:0] z0, z1, z2;
        begin
            if (a < 4 || b < 4) begin
                karatsuba_mult = a * b;
            end else begin
                a_high = a[4:2];
                a_low = a[1:0];
                b_high = b[4:2];
                b_low = b[1:0];
                
                z0 = karatsuba_mult(a_low, b_low);
                z2 = karatsuba_mult(a_high, b_high);
                z1 = karatsuba_mult(a_high + a_low, b_high + b_low) - z2 - z0;
                
                karatsuba_mult = (z2 << 4) + (z1 << 2) + z0;
            end
        end
    endfunction
    
    // Vending machine state logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= 5'd0;
            dispense <= 1'b0;
        end else begin
            state <= next_state;
            
            // Update dispense signal based on state
            if ((state >= 5'd20 && state < 5'd30 && coin != 2'b00) ||
                (state >= 5'd30)) begin
                dispense <= 1'b1;
            end else begin
                dispense <= 1'b0;
            end
        end
    end
    
    // Next state logic
    always @(*) begin
        reg [4:0] coin_value;
        
        // Convert coin input to value using Karatsuba multiplication
        case (coin)
            2'b01: coin_value = 5'd5;
            2'b10: coin_value = 5'd10;
            2'b11: coin_value = 5'd25;
            default: coin_value = 5'd0;
        endcase
        
        next_state = state + coin_value;
        
        if ((state >= 5'd20 && state < 5'd30 && coin != 2'b00) ||
            (state >= 5'd30)) begin
            next_state = 5'd0;
        end
    end
    
    // AXI4-Lite write address channel
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b1;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                s_axil_awready <= 1'b0;
            end else if (axi_state == IDLE) begin
                s_axil_awready <= 1'b1;
            end
        end
    end
    
    // AXI4-Lite write data channel
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready <= 1'b0;
        end else begin
            if (axi_state == WRITE_ADDR) begin
                s_axil_wready <= 1'b1;
            end else if (s_axil_wvalid && s_axil_wready) begin
                s_axil_wready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite write response channel
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            if (axi_state == WRITE_DATA) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b00; // OKAY response
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite read address channel
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b1;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                s_axil_arready <= 1'b0;
            end else if (axi_state == IDLE) begin
                s_axil_arready <= 1'b1;
            end
        end
    end
    
    // AXI4-Lite read data channel
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
        end else begin
            if (axi_state == READ_ADDR) begin
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= 2'b00; // OKAY response
                
                case (s_axil_araddr[5:2])
                    ADDR_STATE: s_axil_rdata <= {27'b0, state};
                    ADDR_CONTROL: s_axil_rdata <= control_reg;
                    ADDR_STATUS: s_axil_rdata <= status_reg;
                    default: s_axil_rdata <= 32'h0;
                endcase
            end else if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            axi_state <= IDLE;
        end else begin
            case (axi_state)
                IDLE: begin
                    if (s_axil_awvalid && s_axil_awready) begin
                        axi_state <= WRITE_ADDR;
                    end else if (s_axil_arvalid && s_axil_arready) begin
                        axi_state <= READ_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        axi_state <= WRITE_DATA;
                    end
                end
                
                WRITE_DATA: begin
                    if (s_axil_bvalid && s_axil_bready) begin
                        axi_state <= IDLE;
                    end
                end
                
                READ_ADDR: begin
                    if (s_axil_rvalid && s_axil_rready) begin
                        axi_state <= IDLE;
                    end
                end
                
                default: axi_state <= IDLE;
            endcase
        end
    end
    
    // Register write logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            control_reg <= 32'h0;
            coin <= 2'b00;
        end else begin
            if (axi_state == WRITE_DATA && s_axil_wvalid && s_axil_wready) begin
                case (s_axil_awaddr[5:2])
                    ADDR_CONTROL: begin
                        control_reg <= s_axil_wdata;
                        coin <= s_axil_wdata[1:0];
                    end
                    default: ;
                endcase
            end
        end
    end
    
    // Status register update
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            status_reg <= 32'h0;
        end else begin
            status_reg <= {27'b0, state, dispense};
        end
    end
    
endmodule