//SystemVerilog
module diff_manchester_codec (
    // Clock and Reset
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite Slave Interface - Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite Slave Interface - Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite Slave Interface - Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite Slave Interface - Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite Slave Interface - Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // External Interface
    input wire diff_manch_in,     // For decoding
    output wire diff_manch_out,   // Encoded output
    output wire data_out,         // Decoded output
    output wire data_valid        // Valid decoded bit
);

    // Internal registers for codec operation
    reg prev_encoded;
    reg [1:0] sample_count;
    
    // Internal registers for AXI4-Lite memory-mapped interface
    reg data_in_reg;
    reg diff_manch_out_reg;
    reg data_out_reg;
    reg data_valid_reg;
    
    // Register addresses (word-aligned)
    localparam ADDR_CONTROL = 4'h0;    // Control register (bit 0: data_in)
    localparam ADDR_STATUS = 4'h4;     // Status register (bits: encoded output, decoded output, valid)
    
    // State machine for write transaction
    reg [1:0] write_state;
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    // State machine for read transaction
    reg [1:0] read_state;
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;

    // AXI4-Lite Write State Machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            write_state <= WRITE_IDLE;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    if (s_axil_awvalid && s_axil_awready)
                        write_state <= WRITE_ADDR;
                end
                
                WRITE_ADDR: begin
                    if (s_axil_wvalid && s_axil_wready)
                        write_state <= WRITE_RESP;
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid)
                        write_state <= WRITE_IDLE;
                end
                
                default: begin
                    write_state <= WRITE_IDLE;
                end
            endcase
        end
    end

    // AXI4-Lite Write Channel Ready/Valid Control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    if (s_axil_awvalid && s_axil_awready)
                        s_axil_awready <= 1'b0;
                end
                
                WRITE_ADDR: begin
                    s_axil_wready <= 1'b1;
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00; // OKAY response
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        s_axil_awready <= 1'b1;
                    end
                end
                
                default: begin
                    s_axil_awready <= 1'b0;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                end
            endcase
        end
    end

    // Write data to registers based on address
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            data_in_reg <= 1'b0;
        end else if (write_state == WRITE_ADDR && s_axil_wvalid && s_axil_wready) begin
            case (s_axil_awaddr[3:0])
                ADDR_CONTROL: begin
                    if (s_axil_wstrb[0]) 
                        data_in_reg <= s_axil_wdata[0];
                end
                default: begin
                    // Invalid address - no effect
                end
            endcase
        end
    end

    // AXI4-Lite Read State Machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            read_state <= READ_IDLE;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    if (s_axil_arvalid && s_axil_arready)
                        read_state <= READ_ADDR;
                end
                
                READ_ADDR: begin
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axil_rready && s_axil_rvalid)
                        read_state <= READ_IDLE;
                end
                
                default: begin
                    read_state <= READ_IDLE;
                end
            endcase
        end
    end

    // AXI4-Lite Read Channel Ready/Valid Control
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
        end else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    if (s_axil_arvalid && s_axil_arready)
                        s_axil_arready <= 1'b0;
                end
                
                READ_ADDR: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY response
                end
                
                READ_DATA: begin
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        s_axil_arready <= 1'b1;
                    end
                end
                
                default: begin
                    s_axil_arready <= 1'b0;
                    s_axil_rvalid <= 1'b0;
                end
            endcase
        end
    end

    // Read data from registers based on address
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rdata <= 32'h0;
        end else if (read_state == READ_ADDR) begin
            case (s_axil_araddr[3:0])
                ADDR_CONTROL: begin
                    s_axil_rdata <= {31'h0, data_in_reg};
                end
                ADDR_STATUS: begin
                    s_axil_rdata <= {29'h0, data_valid_reg, data_out_reg, diff_manch_out_reg};
                end
                default: begin
                    s_axil_rdata <= 32'h0;
                end
            endcase
        end
    end
    
    // Sample counter for Manchester encoding/decoding timing
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            sample_count <= 2'b00;
        end else begin
            sample_count <= sample_count + 1'b1;
        end
    end

    // Differential Manchester encoding - first half of bit time
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            diff_manch_out_reg <= 1'b0;
            prev_encoded <= 1'b0;
        end else begin
            if (sample_count == 2'b00) begin // Start of bit time
                diff_manch_out_reg <= data_in_reg ? prev_encoded : ~prev_encoded;
            end else if (sample_count == 2'b10) begin // Mid-bit transition
                diff_manch_out_reg <= ~diff_manch_out_reg;
                prev_encoded <= diff_manch_out_reg;
            end
        end
    end
    
    // Differential Manchester decoding logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            data_out_reg <= 1'b0;
            data_valid_reg <= 1'b0;
        end else begin
            if (sample_count == 2'b11) begin
                data_valid_reg <= 1'b1;
                data_out_reg <= diff_manch_in; // Simplified - actual decoding would be more complex
            end else begin
                data_valid_reg <= 1'b0;
            end
        end
    end
    
    // Connect internal registers to output ports
    assign diff_manch_out = diff_manch_out_reg;
    assign data_out = data_out_reg;
    assign data_valid = data_valid_reg;

endmodule