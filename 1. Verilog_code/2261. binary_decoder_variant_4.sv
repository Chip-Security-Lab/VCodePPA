//SystemVerilog
module binary_decoder_axi(
    // Global signals
    input wire aclk,
    input wire aresetn,
    
    // AXI4-Lite slave interface - Write address channel
    input wire [31:0] s_axil_awaddr,
    input wire [2:0] s_axil_awprot,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // AXI4-Lite slave interface - Write data channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // AXI4-Lite slave interface - Write response channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // AXI4-Lite slave interface - Read address channel
    input wire [31:0] s_axil_araddr,
    input wire [2:0] s_axil_arprot,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // AXI4-Lite slave interface - Read data channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // Original module output (still exposed for compatibility)
    output reg [15:0] select_out
);

    // Internal registers
    reg [3:0] addr_reg;
    reg write_in_progress;
    reg read_in_progress;
    
    // Pipeline registers for decoder
    reg [3:0] addr_reg_pipe;
    reg [15:0] select_out_pipe;
    
    // First pipeline stage - register address
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            addr_reg_pipe <= 4'b0000;
        end else begin
            addr_reg_pipe <= addr_reg;
        end
    end
    
    // Second pipeline stage - decoder logic
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            select_out_pipe <= 16'b0;
        end else begin
            select_out_pipe <= 16'b0;
            select_out_pipe[addr_reg_pipe] <= 1'b1;
        end
    end
    
    // Final output assignment
    always @(*) begin
        select_out = select_out_pipe;
    end
    
    // AXI4-Lite write channels state machine - pipelined approach
    reg write_addr_received;
    reg write_data_received;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            addr_reg <= 4'b0000;
            write_in_progress <= 1'b0;
            write_addr_received <= 1'b0;
            write_data_received <= 1'b0;
        end else begin
            // Write address channel
            if (s_axil_awvalid && !write_in_progress && !s_axil_awready) begin
                s_axil_awready <= 1'b1;
                write_addr_received <= 1'b1;
            end else if (s_axil_awready) begin
                s_axil_awready <= 1'b0;
            end
            
            // Write data channel
            if (s_axil_wvalid && !s_axil_wready && write_addr_received && !write_data_received) begin
                s_axil_wready <= 1'b1;
                write_data_received <= 1'b1;
                // Update address register (use lowest 4 bits only)
                if (s_axil_wstrb[0]) begin
                    addr_reg <= s_axil_wdata[3:0];
                end
            end else if (s_axil_wready) begin
                s_axil_wready <= 1'b0;
            end
            
            // Write response generation - separated stage
            if (write_data_received && !s_axil_bvalid) begin
                s_axil_bvalid <= 1'b1;
                s_axil_bresp <= 2'b00; // OKAY response
                write_in_progress <= 1'b0;
                write_addr_received <= 1'b0;
                write_data_received <= 1'b0;
            end else if (s_axil_bvalid && s_axil_bready) begin
                s_axil_bvalid <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite read channels state machine - pipelined approach
    reg read_addr_valid;
    reg [31:0] read_data_pipe;
    
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h00000000;
            read_in_progress <= 1'b0;
            read_addr_valid <= 1'b0;
            read_data_pipe <= 32'h00000000;
        end else begin
            // Read address channel
            if (s_axil_arvalid && !read_in_progress && !s_axil_arready) begin
                s_axil_arready <= 1'b1;
                read_addr_valid <= 1'b1;
                read_in_progress <= 1'b1;
            end else if (s_axil_arready) begin
                s_axil_arready <= 1'b0;
            end
            
            // Read data preparation - first stage
            if (read_addr_valid && !s_axil_rvalid) begin
                read_data_pipe <= {28'h0000000, addr_reg};
                read_addr_valid <= 1'b0;
                s_axil_rvalid <= 1'b1;
                s_axil_rresp <= 2'b00; // OKAY response
            end 
            
            // Read data channel - second stage
            if (s_axil_rvalid) begin
                s_axil_rdata <= read_data_pipe;
                if (s_axil_rready) begin
                    s_axil_rvalid <= 1'b0;
                    read_in_progress <= 1'b0;
                end
            end
        end
    end

endmodule