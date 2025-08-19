//SystemVerilog
module multi_io_ctrl (
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite Write Address Channel
    input wire [31:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite Read Address Channel
    input wire [31:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // Original output signals
    output reg scl,
    output reg sda,
    output reg spi_cs,
    output reg data_ready
);

    // Register map (8-bit registers in 32-bit address space)
    // 0x00: Control register [mode_sel(0)]
    // 0x04: Data input register [data_in(7:0)]
    // 0x08: Status register [data_ready(0)]
    
    // Internal registers
    reg mode_sel;
    reg [7:0] data_in;
    reg data_valid;
    
    // Extended Pipeline registers - increased from 2 to 5 stages
    reg mode_sel_stage1, mode_sel_stage2, mode_sel_stage3, mode_sel_stage4, mode_sel_stage5;
    reg [7:0] data_in_stage1, data_in_stage2, data_in_stage3, data_in_stage4, data_in_stage5;
    reg valid_stage1, valid_stage2, valid_stage3, valid_stage4, valid_stage5;
    
    // Data processing intermediate signals
    reg [3:0] bit_position_stage3, bit_position_stage4;
    reg [3:0] data_processed_stage3, data_processed_stage4;
    
    // Internal state registers
    reg scl_state;
    reg scl_next;
    reg sda_next;
    reg spi_cs_next;
    
    // AXI4-Lite interface state machine
    localparam IDLE = 2'b00;
    localparam ADDR = 2'b01;
    localparam DATA = 2'b10;
    localparam RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [1:0] read_state;
    reg [31:0] read_addr;
    reg [31:0] write_addr;
    
    // AXI4-Lite Write Channel Logic - Split into address capture and data handling stages
    reg write_addr_valid;
    reg [31:0] write_addr_captured;
    
    // First stage of AXI write - address capture
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            write_addr_valid <= 1'b0;
            write_addr_captured <= 32'h0;
        end else begin
            if (s_axi_awvalid && !write_addr_valid && (write_state == IDLE)) begin
                s_axi_awready <= 1'b1;
                write_addr_captured <= s_axi_awaddr;
                write_addr_valid <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
                if (write_state != IDLE) begin
                    write_addr_valid <= 1'b0;
                end
            end
        end
    end
    
    // Second stage of AXI write - data handling and state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00;
            write_state <= IDLE;
            write_addr <= 32'h0;
            mode_sel <= 1'b0;
            data_in <= 8'h0;
            data_valid <= 1'b0;
        end else begin
            // Default values
            data_valid <= 1'b0;
            
            case (write_state)
                IDLE: begin
                    s_axi_bvalid <= 1'b0;  // Clear any previous response
                    if (write_addr_valid) begin
                        write_addr <= write_addr_captured;
                        write_state <= ADDR;
                    end
                end
                
                ADDR: begin
                    if (s_axi_wvalid) begin
                        s_axi_wready <= 1'b1;
                        
                        // Write to appropriate register based on address
                        case (write_addr[7:0])
                            8'h00: begin  // Control register
                                mode_sel <= s_axi_wdata[0];
                                data_valid <= 1'b1;  // Trigger processing pipeline
                            end
                            8'h04: begin  // Data register
                                data_in <= s_axi_wdata[7:0];
                                data_valid <= 1'b1;  // Trigger processing pipeline
                            end
                            default: begin
                                // Invalid address - do nothing
                            end
                        endcase
                        
                        write_state <= DATA;
                    end
                end
                
                DATA: begin
                    s_axi_wready <= 1'b0;
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp <= 2'b00;  // OKAY response
                    write_state <= RESP;
                end
                
                RESP: begin
                    if (s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        write_state <= IDLE;
                    end
                end
            endcase
        end
    end
    
    // Split AXI4-Lite Read Channel Logic into address and data stages
    reg read_addr_valid;
    reg [31:0] read_addr_captured;
    
    // First stage of AXI read - address capture
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            read_addr_valid <= 1'b0;
            read_addr_captured <= 32'h0;
        end else begin
            if (s_axi_arvalid && !read_addr_valid && (read_state == IDLE)) begin
                s_axi_arready <= 1'b1;
                read_addr_captured <= s_axi_araddr;
                read_addr_valid <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
                if (read_state != IDLE) begin
                    read_addr_valid <= 1'b0;
                end
            end
        end
    end
    
    // Second stage of AXI read - data handling and state machine
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00;
            s_axi_rdata <= 32'h0;
            read_state <= IDLE;
            read_addr <= 32'h0;
        end else begin
            case (read_state)
                IDLE: begin
                    if (read_addr_valid) begin
                        read_addr <= read_addr_captured;
                        read_state <= ADDR;
                    end
                end
                
                ADDR: begin
                    s_axi_rvalid <= 1'b1;
                    s_axi_rresp <= 2'b00;  // OKAY response
                    
                    // Read from appropriate register based on address
                    case (read_addr[7:0])
                        8'h00: begin  // Control register
                            s_axi_rdata <= {31'b0, mode_sel};
                        end
                        8'h04: begin  // Data register
                            s_axi_rdata <= {24'b0, data_in};
                        end
                        8'h08: begin  // Status register
                            s_axi_rdata <= {31'b0, data_ready};
                        end
                        default: begin
                            s_axi_rdata <= 32'h0;
                        end
                    endcase
                    
                    read_state <= DATA;
                end
                
                DATA: begin
                    if (s_axi_rready) begin
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
    
    // First pipeline stage: Input registration
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            mode_sel_stage1 <= 0;
            data_in_stage1 <= 8'h0;
            valid_stage1 <= 0;
        end else if (data_valid) begin
            mode_sel_stage1 <= mode_sel;
            data_in_stage1 <= data_in;
            valid_stage1 <= 1;
        end else begin
            valid_stage1 <= 0;
        end
    end
    
    // Second pipeline stage: Initial processing
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            mode_sel_stage2 <= 0;
            data_in_stage2 <= 8'h0;
            valid_stage2 <= 0;
        end else begin
            mode_sel_stage2 <= mode_sel_stage1;
            data_in_stage2 <= data_in_stage1;
            valid_stage2 <= valid_stage1;
        end
    end
    
    // Third pipeline stage: Protocol selection and bit extraction
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            mode_sel_stage3 <= 0;
            data_in_stage3 <= 8'h0;
            valid_stage3 <= 0;
            bit_position_stage3 <= 4'h7;  // Starting with MSB
            data_processed_stage3 <= 4'h0;
        end else begin
            mode_sel_stage3 <= mode_sel_stage2;
            data_in_stage3 <= data_in_stage2;
            valid_stage3 <= valid_stage2;
            
            if (valid_stage2) begin
                bit_position_stage3 <= 4'h7;  // Start with MSB
                // Pre-process data based on mode
                if (mode_sel_stage2) begin  // I2C mode
                    data_processed_stage3 <= {data_in_stage2[7], 3'b0};  // Extract MSB for I2C
                end else begin              // SPI mode
                    data_processed_stage3 <= {data_in_stage2[0], 3'b0};  // Extract LSB for SPI CS
                end
            end else begin
                // Update bit position for next clock cycle when processing multi-bit data
                if (bit_position_stage3 > 0) begin
                    bit_position_stage3 <= bit_position_stage3 - 1;
                end
            end
        end
    end
    
    // Fourth pipeline stage: Signal generation logic
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            mode_sel_stage4 <= 0;
            data_in_stage4 <= 8'h0;
            valid_stage4 <= 0;
            bit_position_stage4 <= 4'h0;
            data_processed_stage4 <= 4'h0;
            scl_next <= 0;
            sda_next <= 0;
            spi_cs_next <= 1;
        end else begin
            mode_sel_stage4 <= mode_sel_stage3;
            data_in_stage4 <= data_in_stage3;
            valid_stage4 <= valid_stage3;
            bit_position_stage4 <= bit_position_stage3;
            data_processed_stage4 <= data_processed_stage3;
            
            if (valid_stage3) begin
                if (mode_sel_stage3) begin // I2C mode
                    scl_next <= ~scl_state; // Toggle SCL
                    sda_next <= data_processed_stage3[3]; // MSB from preprocessed data
                    spi_cs_next <= 1; // Inactive in I2C mode
                end else begin // SPI mode
                    scl_next <= 0; // Not used in SPI mode
                    sda_next <= 0; // Not used in SPI mode
                    spi_cs_next <= data_processed_stage3[3]; // CS from preprocessed data
                end
            end
        end
    end
    
    // Fifth pipeline stage: Output registration
    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            mode_sel_stage5 <= 0;
            data_in_stage5 <= 8'h0;
            valid_stage5 <= 0;
            scl <= 0;
            sda <= 0;
            spi_cs <= 1; // SPI chip select usually defaults to high (not selected)
            scl_state <= 0;
            data_ready <= 1;
        end else begin
            mode_sel_stage5 <= mode_sel_stage4;
            data_in_stage5 <= data_in_stage4;
            valid_stage5 <= valid_stage4;
            
            if (valid_stage4) begin
                scl <= scl_next;
                sda <= sda_next;
                spi_cs <= spi_cs_next;
                scl_state <= scl_next; // Store current state for next toggle
                data_ready <= 1;
            end
        end
    end

endmodule