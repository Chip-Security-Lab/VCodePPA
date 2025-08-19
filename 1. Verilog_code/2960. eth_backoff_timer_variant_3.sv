//SystemVerilog
module eth_backoff_timer (
    // Global signals
    input wire s_axi_aclk,
    input wire s_axi_aresetn,
    
    // AXI4-Lite write address channel
    input wire [31:0] s_axi_awaddr,
    input wire [2:0] s_axi_awprot,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // AXI4-Lite write data channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // AXI4-Lite write response channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // AXI4-Lite read address channel
    input wire [31:0] s_axi_araddr,
    input wire [2:0] s_axi_arprot,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // AXI4-Lite read data channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready
);
    // Register map
    // 0x00: Control register (bit 0: start_backoff)
    // 0x04: Status register (bit 0: backoff_active, bit 1: backoff_complete)
    // 0x08: Collision count (0-15)
    // 0x0C: Backoff time (read-only)
    // 0x10: Current time (read-only)
    // 0x14: Slot time (read/write)
    // 0x18: Random seed (read/write)
    
    // Internal registers and signals
    reg [15:0] slot_time;
    reg [7:0] random_seed;
    reg [15:0] max_slots;
    reg [7:0] next_random_seed;
    reg start_backoff_r;
    reg [3:0] collision_count_r;
    
    // Core functionality signals
    reg start_backoff;
    reg [3:0] collision_count;
    reg backoff_active;
    reg backoff_complete;
    reg [15:0] backoff_time;
    reg [15:0] current_time;
    
    // AXI4-Lite internal signals
    reg [31:0] reg_data_out;
    reg [3:0] byte_index;
    reg aw_en;
    
    // Use a linear-feedback shift register for pseudo-random number generation
    function [7:0] lfsr_next;
        input [7:0] current;
        begin
            lfsr_next = {current[6:0], current[7] ^ current[5] ^ current[4] ^ current[3]};
        end
    endfunction
    
    // Calculate next random seed
    always @(*) begin
        next_random_seed = lfsr_next(random_seed);
    end
    
    // AXI4-Lite write address channel handling
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (s_axi_bready && s_axi_bvalid) begin
                aw_en <= 1'b1;
                s_axi_awready <= 1'b0;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // AXI4-Lite write data channel handling
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_wready <= 1'b0;
            start_backoff <= 1'b0;
            collision_count <= 4'd0;
            slot_time <= 16'd512; // 512 bit times = 64 bytes
            random_seed <= 8'h45; // Arbitrary initial seed
        end else begin
            if (~s_axi_wready && s_axi_wvalid && s_axi_awvalid && aw_en) begin
                s_axi_wready <= 1'b1;
                
                case (s_axi_awaddr[6:2])
                    5'h00: begin // Control register
                        if (s_axi_wstrb[0]) begin
                            start_backoff <= s_axi_wdata[0];
                        end
                    end
                    
                    5'h02: begin // Collision count
                        if (s_axi_wstrb[0]) begin
                            collision_count <= s_axi_wdata[3:0];
                        end
                    end
                    
                    5'h05: begin // Slot time
                        if (s_axi_wstrb[0]) begin
                            slot_time[7:0] <= s_axi_wdata[7:0];
                        end
                        if (s_axi_wstrb[1]) begin
                            slot_time[15:8] <= s_axi_wdata[15:8];
                        end
                    end
                    
                    5'h06: begin // Random seed
                        if (s_axi_wstrb[0]) begin
                            random_seed <= s_axi_wdata[7:0];
                        end
                    end
                    
                    default: begin
                        // Read-only registers are not written
                    end
                endcase
            end else begin
                s_axi_wready <= 1'b0;
                // Auto-clear start_backoff after one cycle
                if (start_backoff) begin
                    start_backoff <= 1'b0;
                end
            end
        end
    end
    
    // AXI4-Lite write response channel handling
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b0;
        end else begin
            if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY response
            end else begin
                if (s_axi_bready && s_axi_bvalid) begin
                    s_axi_bvalid <= 1'b0;
                end
            end
        end
    end
    
    // AXI4-Lite read address channel handling
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
            end
        end
    end
    
    // Read data generation
    always @(*) begin
        case (s_axi_araddr[6:2])
            5'h00: reg_data_out <= {31'b0, start_backoff}; // Control register
            5'h01: reg_data_out <= {30'b0, backoff_complete, backoff_active}; // Status register
            5'h02: reg_data_out <= {28'b0, collision_count}; // Collision count
            5'h03: reg_data_out <= {16'b0, backoff_time}; // Backoff time (read-only)
            5'h04: reg_data_out <= {16'b0, current_time}; // Current time (read-only)
            5'h05: reg_data_out <= {16'b0, slot_time}; // Slot time
            5'h06: reg_data_out <= {24'b0, random_seed}; // Random seed
            default: reg_data_out <= 32'h0;
        endcase
    end
    
    // AXI4-Lite read data channel handling
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b0;
        end else begin
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY response
                s_axi_rdata <= reg_data_out;
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    // Register input signals first to reduce input-to-register delay
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            start_backoff_r <= 1'b0;
            collision_count_r <= 4'd0;
        end else begin
            start_backoff_r <= start_backoff;
            collision_count_r <= collision_count;
        end
    end
    
    // Main control logic with reduced combinational depth before registers
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            backoff_active <= 1'b0;
            backoff_complete <= 1'b0;
            backoff_time <= 16'd0;
            current_time <= 16'd0;
            max_slots <= 16'd0;
        end else begin
            backoff_complete <= 1'b0;
            
            if (start_backoff_r) begin
                // Calculate maximum slots based on collision count (2^k - 1)
                if (collision_count_r >= 10) begin
                    max_slots <= 16'd1023; // 2^10 - 1
                end else begin
                    max_slots <= (16'd1 << collision_count_r) - 16'd1;
                end
                
                // Select random number of slots for backoff
                backoff_time <= (random_seed % (max_slots + 1)) * slot_time;
                current_time <= 16'd0;
                backoff_active <= 1'b1;
            end else if (backoff_active) begin
                // Count up during backoff
                if (current_time < backoff_time) begin
                    current_time <= current_time + 16'd1;
                end else begin
                    backoff_active <= 1'b0;
                    backoff_complete <= 1'b1;
                end
            end
        end
    end
endmodule