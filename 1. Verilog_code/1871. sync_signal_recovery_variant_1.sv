//SystemVerilog
module sync_signal_recovery (
    input  wire        clk,
    input  wire        rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input  wire [31:0] s_axil_awaddr,
    input  wire        s_axil_awvalid,
    output wire        s_axil_awready,
    
    // Write Data Channel
    input  wire [31:0] s_axil_wdata,
    input  wire [3:0]  s_axil_wstrb,
    input  wire        s_axil_wvalid,
    output wire        s_axil_wready,
    
    // Write Response Channel
    output reg  [1:0]  s_axil_bresp,
    output reg         s_axil_bvalid,
    input  wire        s_axil_bready,
    
    // Read Address Channel
    input  wire [31:0] s_axil_araddr,
    input  wire        s_axil_arvalid,
    output wire        s_axil_arready,
    
    // Read Data Channel
    output reg  [31:0] s_axil_rdata,
    output reg  [1:0]  s_axil_rresp,
    output reg         s_axil_rvalid,
    input  wire        s_axil_rready
);

    // Internal registers
    reg [7:0]  data_reg;        // Data register
    reg        data_valid_reg;  // Data valid flag
    reg        last_flag_reg;   // Last data flag
    reg        input_was_valid; // Previous input valid state
    
    // Control and status registers
    localparam ADDR_DATA_REG        = 32'h00000000;
    localparam ADDR_CONTROL_STATUS  = 32'h00000004;
    
    // Write channel signals
    reg  write_address_valid;
    reg  [31:0] write_address;
    reg  write_data_valid;
    reg  [31:0] write_data;
    reg  [3:0]  write_strobe;
    
    // Read channel signals
    reg  read_address_valid;
    reg  [31:0] read_address;
    
    // AXI interface ready signals - simple implementation
    assign s_axil_awready = !write_address_valid;
    assign s_axil_wready = !write_data_valid;
    assign s_axil_arready = !read_address_valid;
    
    // Capture write address
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_address_valid <= 1'b0;
            write_address <= 32'b0;
        end else begin
            if (s_axil_awvalid && s_axil_awready) begin
                write_address_valid <= 1'b1;
                write_address <= s_axil_awaddr;
            end else if (write_data_valid && s_axil_bready && s_axil_bvalid) begin
                write_address_valid <= 1'b0;
            end
        end
    end
    
    // Capture write data
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_data_valid <= 1'b0;
            write_data <= 32'b0;
            write_strobe <= 4'b0;
        end else begin
            if (s_axil_wvalid && s_axil_wready) begin
                write_data_valid <= 1'b1;
                write_data <= s_axil_wdata;
                write_strobe <= s_axil_wstrb;
            end else if (write_address_valid && s_axil_bready && s_axil_bvalid) begin
                write_data_valid <= 1'b0;
            end
        end
    end
    
    // Generate write response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00; // OKAY
        end else begin
            if (write_address_valid && write_data_valid && !s_axil_bvalid) begin
                s_axil_bvalid <= 1'b1;
                
                // Process write
                if (write_address == ADDR_DATA_REG) begin
                    s_axil_bresp <= 2'b00; // OKAY
                end else if (write_address == ADDR_CONTROL_STATUS) begin
                    s_axil_bresp <= 2'b00; // OKAY
                end else begin
                    s_axil_bresp <= 2'b10; // SLVERR for invalid address
                end
            end else if (s_axil_bready && s_axil_bvalid) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // Capture read address
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_address_valid <= 1'b0;
            read_address <= 32'b0;
        end else begin
            if (s_axil_arvalid && s_axil_arready) begin
                read_address_valid <= 1'b1;
                read_address <= s_axil_araddr;
            end else if (s_axil_rready && s_axil_rvalid) begin
                read_address_valid <= 1'b0;
            end
        end
    end
    
    // Generate read response
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axil_rvalid <= 1'b0;
            s_axil_rdata <= 32'b0;
            s_axil_rresp <= 2'b00; // OKAY
        end else begin
            if (read_address_valid && !s_axil_rvalid) begin
                s_axil_rvalid <= 1'b1;
                
                // Read data based on address
                if (read_address == ADDR_DATA_REG) begin
                    s_axil_rdata <= {24'b0, data_reg}; // Return data value
                    s_axil_rresp <= 2'b00; // OKAY
                end else if (read_address == ADDR_CONTROL_STATUS) begin
                    s_axil_rdata <= {29'b0, last_flag_reg, input_was_valid, data_valid_reg}; // Return status
                    s_axil_rresp <= 2'b00; // OKAY
                end else begin
                    s_axil_rdata <= 32'b0;
                    s_axil_rresp <= 2'b10; // SLVERR for invalid address
                end
            end else if (s_axil_rready && s_axil_rvalid) begin
                s_axil_rvalid <= 1'b0;
            end
        end
    end
    
    // Core signal processing logic (maintained from original)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_was_valid <= 1'b0;
        end else begin
            // Update based on write operation
            if (write_address_valid && write_data_valid && write_address == ADDR_DATA_REG && 
                write_strobe[0] && !s_axil_bvalid) begin
                input_was_valid <= 1'b1;
            end else begin
                input_was_valid <= 1'b0;
            end
        end
    end
    
    // Generate last flag similar to original logic
    wire gen_last = input_was_valid && !write_data_valid;
    
    // Data processing with register-based approach
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_reg <= 8'b0;
            data_valid_reg <= 1'b0;
            last_flag_reg <= 1'b0;
        end else begin
            if (write_address_valid && write_data_valid && write_address == ADDR_DATA_REG && 
                write_strobe[0] && !s_axil_bvalid) begin
                // Handle write to data register
                data_reg <= write_data[7:0];
                data_valid_reg <= 1'b1;
                last_flag_reg <= 1'b0;
            end else if (gen_last) begin
                // Set last flag when appropriate
                last_flag_reg <= 1'b1;
            end else if (read_address_valid && read_address == ADDR_DATA_REG && s_axil_rvalid && s_axil_rready) begin
                // Clear valid flag after read
                data_valid_reg <= 1'b0;
                last_flag_reg <= 1'b0;
            end
        end
    end
    
endmodule