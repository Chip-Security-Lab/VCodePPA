//SystemVerilog
module ft_display_codec_axi4lite (
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite slave interface
    // Write address channel
    input wire [31:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write data channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write response channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read address channel
    input wire [31:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read data channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Core outputs (could be routed to other modules)
    output wire [19:0] protected_out,
    output wire error_detected,
    output wire [15:0] rgb565_out
);

    // Internal registers for control and status
    reg [23:0] rgb_in_reg;
    reg data_valid_reg;
    reg ecc_enable_reg;
    
    // Internal signals
    reg [19:0] protected_out_reg;
    reg error_detected_reg;
    reg [15:0] rgb565_out_reg;
    
    // Core processing signals
    reg [15:0] rgb565;
    reg [3:0] ecc_bits;
    reg [3:0] syndrome;
    
    // Address decode parameters
    localparam ADDR_RGB_IN       = 4'h0;
    localparam ADDR_CTRL_STATUS  = 4'h1;
    localparam ADDR_PROTECTED    = 4'h2;
    localparam ADDR_RGB565_OUT   = 4'h3;
    
    // AXI state machine states
    localparam IDLE      = 2'b00;
    localparam ADDR_RCV  = 2'b01;
    localparam DATA_TX   = 2'b10;
    localparam RESP      = 2'b11;
    
    // Write state machine
    reg [1:0] write_state;
    reg [3:0] write_addr;
    
    // Read state machine
    reg [1:0] read_state;
    reg [3:0] read_addr;
    
    // Output assignments
    assign protected_out = protected_out_reg;
    assign error_detected = error_detected_reg;
    assign rgb565_out = rgb565_out_reg;
    
    // Hamming code generation function (simplified)
    function [3:0] gen_hamming;
        input [15:0] data;
        begin
            gen_hamming[0] = ^{data[0], data[1], data[3], data[4], data[6], data[8], data[10], data[11], data[13], data[15]};
            gen_hamming[1] = ^{data[0], data[2], data[3], data[5], data[6], data[9], data[10], data[12], data[13]};
            gen_hamming[2] = ^{data[1], data[2], data[3], data[7], data[8], data[9], data[10], data[14], data[15]};
            gen_hamming[3] = ^{data[4], data[5], data[6], data[7], data[8], data[9], data[10]};
        end
    endfunction
    
    // Error correction function (simplified)
    function [15:0] correct_error;
        input [15:0] data;
        input [3:0] syndrome;
        reg [15:0] result;
        begin
            result = data;
            case (syndrome)
                4'h1: result[0] = ~data[0];
                4'h2: result[1] = ~data[1];
                4'h3: result[2] = ~data[2];
                4'h4: result[3] = ~data[3];
                4'h5: result[4] = ~data[4];
                4'h6: result[5] = ~data[5];
                4'h7: result[6] = ~data[6];
                4'h8: result[7] = ~data[7];
                4'h9: result[8] = ~data[8];
                4'hA: result[9] = ~data[9];
                4'hB: result[10] = ~data[10];
                4'hC: result[11] = ~data[11];
                4'hD: result[12] = ~data[12];
                4'hE: result[13] = ~data[13];
                4'hF: result[14] = ~data[14];
                // Default case handles no error or double error
            endcase
            correct_error = result;
        end
    endfunction
    
    // Core processing logic
    always @(posedge aclk) begin
        if (!aresetn) begin
            rgb565 <= 16'h0000;
            ecc_bits <= 4'h0;
            protected_out_reg <= 20'h00000;
            error_detected_reg <= 1'b0;
            rgb565_out_reg <= 16'h0000;
            syndrome <= 4'h0;
        end else if (data_valid_reg) begin
            // RGB888 to RGB565 conversion
            rgb565 <= {rgb_in_reg[23:19], rgb_in_reg[15:10], rgb_in_reg[7:3]};
            
            // Generate ECC bits if enabled
            if (ecc_enable_reg) begin
                ecc_bits <= gen_hamming(rgb565);
                protected_out_reg <= {rgb565, ecc_bits};
                
                // Error detection and correction
                syndrome <= ecc_bits ^ gen_hamming(rgb565);
                error_detected_reg <= (syndrome != 4'h0);
                rgb565_out_reg <= correct_error(rgb565, syndrome);
            end else begin
                // Bypass ECC
                protected_out_reg <= {rgb565, 4'h0};
                error_detected_reg <= 1'b0;
                rgb565_out_reg <= rgb565;
            end
        end
    end
    
    // AXI4-Lite write channel management
    always @(posedge aclk) begin
        if (!aresetn) begin
            write_state <= IDLE;
            s_axi_awready <= 1'b0;
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            rgb_in_reg <= 24'h0;
            data_valid_reg <= 1'b0;
            ecc_enable_reg <= 1'b0;
        end else begin
            // Default assignment - auto-clear data_valid signal
            if (data_valid_reg) begin
                data_valid_reg <= 1'b0;
            end
            
            case (write_state)
                IDLE: begin
                    s_axi_awready <= 1'b1;
                    if (s_axi_awvalid && s_axi_awready) begin
                        write_addr <= s_axi_awaddr[5:2]; // Capture address
                        s_axi_awready <= 1'b0;
                        s_axi_wready <= 1'b1;
                        write_state <= ADDR_RCV;
                    end
                end
                
                ADDR_RCV: begin
                    if (s_axi_wvalid && s_axi_wready) begin
                        s_axi_wready <= 1'b0;
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp <= 2'b00; // OKAY response
                        
                        // Handle register writes based on address
                        case (write_addr)
                            ADDR_RGB_IN: begin
                                rgb_in_reg <= s_axi_wdata[23:0];
                            end
                            ADDR_CTRL_STATUS: begin
                                data_valid_reg <= s_axi_wdata[0];
                                ecc_enable_reg <= s_axi_wdata[1];
                            end
                            default: begin
                                // Invalid address, but still acknowledge
                                s_axi_bresp <= 2'b10; // SLVERR response
                            end
                        endcase
                        
                        write_state <= RESP;
                    end
                end
                
                RESP: begin
                    if (s_axi_bready && s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
                
                default: begin
                    write_state <= IDLE;
                end
            endcase
        end
    end
    
    // AXI4-Lite read channel management
    always @(posedge aclk) begin
        if (!aresetn) begin
            read_state <= IDLE;
            s_axi_arready <= 1'b0;
            s_axi_rvalid <= 1'b0;
            s_axi_rdata <= 32'h0;
            s_axi_rresp <= 2'b00;
        end else begin
            case (read_state)
                IDLE: begin
                    s_axi_arready <= 1'b1;
                    if (s_axi_arvalid && s_axi_arready) begin
                        read_addr <= s_axi_araddr[5:2]; // Capture address
                        s_axi_arready <= 1'b0;
                        read_state <= ADDR_RCV;
                    end
                end
                
                ADDR_RCV: begin
                    s_axi_rvalid <= 1'b1;
                    
                    // Prepare read data based on address
                    case (read_addr)
                        ADDR_RGB_IN: begin
                            s_axi_rdata <= {8'h00, rgb_in_reg};
                            s_axi_rresp <= 2'b00; // OKAY
                        end
                        ADDR_CTRL_STATUS: begin
                            s_axi_rdata <= {29'h0, error_detected_reg, ecc_enable_reg, data_valid_reg};
                            s_axi_rresp <= 2'b00; // OKAY
                        end
                        ADDR_PROTECTED: begin
                            s_axi_rdata <= {12'h000, protected_out_reg};
                            s_axi_rresp <= 2'b00; // OKAY
                        end
                        ADDR_RGB565_OUT: begin
                            s_axi_rdata <= {16'h0000, rgb565_out_reg};
                            s_axi_rresp <= 2'b00; // OKAY
                        end
                        default: begin
                            s_axi_rdata <= 32'h0;
                            s_axi_rresp <= 2'b10; // SLVERR
                        end
                    endcase
                    
                    read_state <= DATA_TX;
                end
                
                DATA_TX: begin
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                        read_state <= IDLE;
                    end
                end
                
                default: begin
                    read_state <= IDLE;
                end
            endcase
        end
    end
    
endmodule