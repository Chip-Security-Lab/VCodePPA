//SystemVerilog
module i2c_repeated_start_slave_axi4lite(
    // Global Signals
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
    
    // I2C Interface
    input wire [6:0] self_addr,
    inout wire sda,
    inout wire scl
);

    // I2C internal signals
    reg [2:0] state;
    reg sda_r, scl_r;                 // Input synchronizers stage 1
    reg sda_r2, scl_r2;               // Input synchronizers stage 2
    reg sda_r3, scl_r3;               // Added pipeline stage for better timing
    reg [7:0] shift_reg;
    reg [3:0] bit_idx;
    reg [7:0] data_received;
    reg repeated_start_detected;
    
    // Pipeline for start condition detection
    reg start_cond_p1;                // Pipeline stage 1
    reg start_condition;              // Final output of start condition detection
    
    // I2C signal synchronization and pipeline
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            sda_r <= 1'b1;
            scl_r <= 1'b1;
            sda_r2 <= 1'b1;
            scl_r2 <= 1'b1;
            sda_r3 <= 1'b1;
            scl_r3 <= 1'b1;
        end else begin
            // Input synchronizers
            sda_r <= sda;
            scl_r <= scl;
            sda_r2 <= sda_r;
            scl_r2 <= scl_r;
            sda_r3 <= sda_r2;
            scl_r3 <= scl_r2;
        end
    end
    
    // Pipelined start condition detection
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            start_cond_p1 <= 1'b0;
            start_condition <= 1'b0;
        end else begin
            // First stage: detect SDA falling while SCL is high
            start_cond_p1 <= scl_r2 && sda_r3 && !sda_r2;
            // Second stage: register the start condition
            start_condition <= start_cond_p1;
        end
    end
    
    // I2C controller state machine (clocked by aclk for better timing)
    reg [2:0] i2c_state_r;
    reg repeated_start_r;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            i2c_state_r <= 3'b000;
            repeated_start_r <= 1'b0;
        end else begin
            if (start_condition && (i2c_state_r != 3'b000)) begin
                repeated_start_r <= 1'b1;
                i2c_state_r <= 3'b001;
            end
        end
    end
    
    // Register update logic with synchronizers
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= 3'b000;
            repeated_start_detected <= 1'b0;
        end else begin
            state <= i2c_state_r;
            repeated_start_detected <= repeated_start_r;
        end
    end
    
    // AXI4-Lite registers and address mapping pipeline stages
    reg [7:0] araddr_reg;             // Pipeline register for address
    reg araddr_valid;                 // Address valid signal
    
    // Register addresses:
    // 0x00: data_received (read only)
    // 0x04: repeated_start_detected (read only)
    // 0x08: self_addr (read only)
    
    // AXI4-Lite write address channel handler
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
        end else begin
            // All registers are read-only in this implementation
            s_axil_awready <= s_axil_awvalid;
        end
    end
    
    // AXI4-Lite write data channel handler
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_wready <= 1'b0;
        end else begin
            // All registers are read-only in this implementation
            s_axil_wready <= s_axil_wvalid;
        end
    end
    
    // AXI4-Lite write response channel handler - pipelined
    reg awready_and_valid, wready_and_valid;
    reg bvalid_pre;  // Pipeline stage for bvalid
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            awready_and_valid <= 1'b0;
            wready_and_valid <= 1'b0;
            bvalid_pre <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
        end else begin
            // First stage: detect ready and valid conditions
            awready_and_valid <= s_axil_awready && s_axil_awvalid;
            wready_and_valid <= s_axil_wready && s_axil_wvalid;
            
            // Second stage: prepare bvalid
            if (awready_and_valid && wready_and_valid && !bvalid_pre && !s_axil_bvalid) begin
                bvalid_pre <= 1'b1;
                // SLVERR response since all registers are read-only
            end else if (s_axil_bvalid && s_axil_bready) begin
                bvalid_pre <= 1'b0;
            end
            
            // Third stage: set bvalid output
            if (bvalid_pre && !s_axil_bvalid) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b10; // SLVERR
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite read address channel handler - pipelined
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            araddr_reg <= 8'h00;
            araddr_valid <= 1'b0;
        end else begin
            // First stage: capture read address
            if (s_axil_arvalid && !s_axil_arready && !araddr_valid) begin
                s_axil_arready <= 1'b1;
                araddr_reg <= s_axil_araddr[7:0];
            end else begin
                s_axil_arready <= 1'b0;
            end
            
            // Second stage: set address valid flag
            if (s_axil_arready && s_axil_arvalid) begin
                araddr_valid <= 1'b1;
            end else if (s_axil_rvalid && s_axil_rready) begin
                araddr_valid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite read data preparation - pipelined
    reg [31:0] rdata_pre;  // Pipeline stage for read data
    reg [1:0] rresp_pre;   // Pipeline stage for read response
    reg rvalid_pre;        // Pipeline stage for read valid
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rdata_pre <= 32'h00000000;
            rresp_pre <= 2'b00;
            rvalid_pre <= 1'b0;
        end else if (araddr_valid && !rvalid_pre && !s_axil_rvalid) begin
            rvalid_pre <= 1'b1;
            rresp_pre <= 2'b00; // OKAY response
            
            // Read address decoding
            case (araddr_reg)
                8'h00: rdata_pre <= {24'h000000, data_received};
                8'h04: rdata_pre <= {31'h0000000, repeated_start_detected};
                8'h08: rdata_pre <= {25'h0000000, self_addr};
                default: begin
                    rdata_pre <= 32'h00000000;
                    rresp_pre <= 2'b10; // SLVERR for undefined addresses
                end
            endcase
        end else if (s_axil_rvalid && s_axil_rready) begin
            rvalid_pre <= 1'b0;
        end
    end
    
    // AXI4-Lite read data channel output - final stage
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h00000000;
        end else if (rvalid_pre && !s_axil_rvalid) begin
            s_axil_rvalid <= 1'b1;
            s_axil_rresp <= rresp_pre;
            s_axil_rdata <= rdata_pre;
        end else if (s_axil_rvalid && s_axil_rready) begin
            s_axil_rvalid <= 1'b0;
        end
    end

endmodule