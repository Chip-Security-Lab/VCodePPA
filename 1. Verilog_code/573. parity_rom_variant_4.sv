//SystemVerilog
module parity_rom (
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
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
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready
);

    // ROM and parity data storage
    reg [8:0] rom [0:15]; // 包含1位奇偶校验
    reg [7:0] data;
    reg parity_error;
    
    // AXI4-Lite control signals
    reg read_in_progress;
    reg write_in_progress;
    reg s_axil_rvalid_reg;
    reg s_axil_bvalid_reg;
    reg s_axil_arready_reg;
    reg s_axil_awready_reg;
    reg s_axil_wready_reg;
    
    // Initialize ROM data
    initial begin
        rom[0] = 9'b000100010; // Data = 0x12, Parity = 0
        rom[1] = 9'b001101000; // Data = 0x34, Parity = 0
        rom[2] = 9'b010101101; // Data = 0x56, Parity = 1
        rom[3] = 9'b011110000; // Data = 0x78, Parity = 0
        rom[4] = 9'b100100001; // Data = 0x91, Parity = 1
        rom[5] = 9'b101001010; // Data = 0xA2, Parity = 0
        rom[6] = 9'b110010100; // Data = 0xC4, Parity = 0
        rom[7] = 9'b111111111; // Data = 0xFF, Parity = 1
        rom[8] = 9'b000011110; // Data = 0x1E, Parity = 0
        rom[9] = 9'b001010101; // Data = 0x2A, Parity = 1
        rom[10] = 9'b010110011; // Data = 0x59, Parity = 1
        rom[11] = 9'b011001100; // Data = 0x66, Parity = 0
        rom[12] = 9'b100111000; // Data = 0x9C, Parity = 0
        rom[13] = 9'b101010011; // Data = 0xA9, Parity = 1
        rom[14] = 9'b110001011; // Data = 0xC5, Parity = 1
        rom[15] = 9'b111100110; // Data = 0xE6, Parity = 0
    end
    
    // AXI4-Lite output assignments
    assign s_axil_arready = s_axil_arready_reg;
    assign s_axil_rvalid = s_axil_rvalid_reg;
    assign s_axil_rresp = 2'b00; // Always OKAY
    
    assign s_axil_awready = s_axil_awready_reg;
    assign s_axil_wready = s_axil_wready_reg;
    assign s_axil_bvalid = s_axil_bvalid_reg;
    assign s_axil_bresp = 2'b00; // Always OKAY
    
    // Core ROM logic - with address decoding
    always @(*) begin
        if (read_in_progress) begin
            // ROM address is in the lower 4 bits of the AXI address
            data = rom[s_axil_araddr[3:0]][7:0];
            parity_error = (rom[s_axil_araddr[3:0]][8] != ^data);
        end else begin
            data = 8'h00;
            parity_error = 1'b0;
        end
    end
    
    // AXI4-Lite Read Channels
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready_reg <= 1'b1;
            s_axil_rvalid_reg <= 1'b0;
            read_in_progress <= 1'b0;
            s_axil_rdata <= 32'h0;
        end else begin
            // Read Address Channel handshake
            if (s_axil_arvalid && s_axil_arready) begin
                s_axil_arready_reg <= 1'b0;
                read_in_progress <= 1'b1;
                s_axil_rvalid_reg <= 1'b1;
                
                // Prepare read data - format data and parity_error in the output register
                s_axil_rdata <= {23'h0, parity_error, data};
            end
            
            // Read Data Channel handshake
            if (s_axil_rvalid && s_axil_rready) begin
                s_axil_rvalid_reg <= 1'b0;
                s_axil_arready_reg <= 1'b1;
                read_in_progress <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite Write Channels (ROM is read-only, but protocol requires response)
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready_reg <= 1'b1;
            s_axil_wready_reg <= 1'b1;
            s_axil_bvalid_reg <= 1'b0;
            write_in_progress <= 1'b0;
        end else begin
            // Write Address & Data channels handshake (accept but ignore writes)
            if (s_axil_awvalid && s_axil_awready && s_axil_wvalid && s_axil_wready && !write_in_progress) begin
                s_axil_awready_reg <= 1'b0;
                s_axil_wready_reg <= 1'b0;
                write_in_progress <= 1'b1;
                s_axil_bvalid_reg <= 1'b1;
            end
            
            // Write Response channel handshake
            if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid_reg <= 1'b0;
                s_axil_awready_reg <= 1'b1;
                s_axil_wready_reg <= 1'b1;
                write_in_progress <= 1'b0;
            end
        end
    end

endmodule