//SystemVerilog
module serial_to_parallel_demux (
    input  wire        s_axi_aclk,          // AXI clock signal
    input  wire        s_axi_aresetn,       // AXI reset signal (active low)
    
    // AXI4-Lite slave interface - Write Address Channel
    input  wire [31:0] s_axi_awaddr,        // Write address
    input  wire        s_axi_awvalid,       // Write address valid
    output reg         s_axi_awready,       // Write address ready
    
    // AXI4-Lite slave interface - Write Data Channel
    input  wire [31:0] s_axi_wdata,         // Write data
    input  wire [3:0]  s_axi_wstrb,         // Write strobes
    input  wire        s_axi_wvalid,        // Write valid
    output reg         s_axi_wready,        // Write ready
    
    // AXI4-Lite slave interface - Write Response Channel
    output reg [1:0]   s_axi_bresp,         // Write response
    output reg         s_axi_bvalid,        // Write response valid
    input  wire        s_axi_bready,        // Write response ready
    
    // AXI4-Lite slave interface - Read Address Channel
    input  wire [31:0] s_axi_araddr,        // Read address
    input  wire        s_axi_arvalid,       // Read address valid
    output reg         s_axi_arready,       // Read address ready
    
    // AXI4-Lite slave interface - Read Data Channel
    output reg [31:0]  s_axi_rdata,         // Read data
    output reg [1:0]   s_axi_rresp,         // Read response
    output reg         s_axi_rvalid,        // Read valid
    input  wire        s_axi_rready,        // Read ready
    
    // Serial interface (kept from original design)
    input  wire        serial_in            // Serial data input
);

    // Internal signals
    reg [7:0]  parallel_out;                // Parallel output data
    reg        load_enable;                 // Load control signal
    
    // Memory map registers (at 4-byte aligned addresses)
    // 0x00: Control Register (bit 0: load_enable)
    // 0x04: Status Register (bits 7:0: parallel_out)
    reg [31:0] control_reg;
    reg [31:0] status_reg;
    
    // Pipeline stage registers (from original design)
    reg [2:0]  bit_counter_stage1;          // Bit position counter - stage 1
    reg        serial_in_stage1;            // Registered input data
    reg        load_enable_stage1;          // Registered load enable
    
    reg [7:0]  parallel_data_stage2;        // Intermediate parallel data - stage 2
    reg [2:0]  bit_counter_stage2;          // Bit counter - stage 2
    reg        valid_stage2;                // Data valid signal - stage 2
    
    // Write address decoding state
    reg        write_addr_valid;
    reg [31:0] write_addr;
    
    // Read address decoding state
    reg        read_addr_valid;
    reg [31:0] read_addr;
    
    // AXI4-Lite write address channel handler
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            write_addr_valid <= 1'b0;
            write_addr <= 32'b0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && ~write_addr_valid) begin
                s_axi_awready <= 1'b1;
                write_addr_valid <= 1'b1;
                write_addr <= s_axi_awaddr;
            end else begin
                s_axi_awready <= 1'b0;
                if (s_axi_wready && s_axi_wvalid && write_addr_valid) begin
                    write_addr_valid <= 1'b0;
                end
            end
        end
    end
    
    // AXI4-Lite write data channel handler
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            control_reg <= 32'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid && write_addr_valid) begin
                s_axi_wready <= 1'b1;
                
                // Handle write to control register
                if (write_addr[7:0] == 8'h00) begin
                    if (s_axi_wstrb[0]) control_reg[7:0] <= s_axi_wdata[7:0];
                    if (s_axi_wstrb[1]) control_reg[15:8] <= s_axi_wdata[15:8];
                    if (s_axi_wstrb[2]) control_reg[23:16] <= s_axi_wdata[23:16];
                    if (s_axi_wstrb[3]) control_reg[31:24] <= s_axi_wdata[31:24];
                end
            end else begin
                s_axi_wready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite write response channel handler
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b0;
        end else begin
            if (s_axi_wready && s_axi_wvalid && ~s_axi_bvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY response
            end else if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite read address channel handler
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            read_addr_valid <= 1'b0;
            read_addr <= 32'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid && ~read_addr_valid) begin
                s_axi_arready <= 1'b1;
                read_addr_valid <= 1'b1;
                read_addr <= s_axi_araddr;
            end else begin
                s_axi_arready <= 1'b0;
                if (s_axi_rvalid && s_axi_rready && read_addr_valid) begin
                    read_addr_valid <= 1'b0;
                end
            end
        end
    end
    
    // AXI4-Lite read data channel handler
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b0;
            s_axi_rdata <= 32'b0;
        end else begin
            if (read_addr_valid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY response
                
                // Address decoding for read operations
                case (read_addr[7:0])
                    8'h00: s_axi_rdata <= control_reg;
                    8'h04: s_axi_rdata <= status_reg;
                    default: s_axi_rdata <= 32'h00000000;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    // Extract load_enable from control register
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            load_enable <= 1'b0;
        end else begin
            load_enable <= control_reg[0];
        end
    end
    
    // Update status register with parallel_out
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            status_reg <= 32'b0;
        end else begin
            status_reg[7:0] <= parallel_out;
        end
    end
    
    // Original serial-to-parallel logic (stage 1)
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            bit_counter_stage1 <= 3'b0;
            serial_in_stage1 <= 1'b0;
            load_enable_stage1 <= 1'b0;
        end else begin
            serial_in_stage1 <= serial_in;
            load_enable_stage1 <= load_enable;
            
            if (load_enable) begin
                bit_counter_stage1 <= bit_counter_stage1 + 1'b1;
            end
        end
    end
    
    // Original serial-to-parallel logic (stage 2)
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            parallel_data_stage2 <= 8'b0;
            bit_counter_stage2 <= 3'b0;
            valid_stage2 <= 1'b0;
        end else begin
            bit_counter_stage2 <= bit_counter_stage1;
            valid_stage2 <= load_enable_stage1;
            
            if (load_enable_stage1) begin
                parallel_data_stage2[bit_counter_stage1] <= serial_in_stage1;
            end
        end
    end
    
    // Original serial-to-parallel logic (stage 3)
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            parallel_out <= 8'b0;
        end else if (valid_stage2) begin
            // When we've completed a full byte, update the output
            if (bit_counter_stage2 == 3'b000) begin
                parallel_out <= parallel_data_stage2;
            end
        end
    end

endmodule