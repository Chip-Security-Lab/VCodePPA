//SystemVerilog
module usb_speed_detector(
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [7:0] s_axi_awaddr,
    input wire s_axi_awvalid,
    output reg s_axi_awready,
    
    // Write Data Channel
    input wire [31:0] s_axi_wdata,
    input wire [3:0] s_axi_wstrb,
    input wire s_axi_wvalid,
    output reg s_axi_wready,
    
    // Write Response Channel
    output reg [1:0] s_axi_bresp,
    output reg s_axi_bvalid,
    input wire s_axi_bready,
    
    // Read Address Channel
    input wire [7:0] s_axi_araddr,
    input wire s_axi_arvalid,
    output reg s_axi_arready,
    
    // Read Data Channel
    output reg [31:0] s_axi_rdata,
    output reg [1:0] s_axi_rresp,
    output reg s_axi_rvalid,
    input wire s_axi_rready,
    
    // USB signals
    input wire dp,
    input wire dm
);

    // Register addresses
    localparam CTRL_REG_ADDR     = 8'h00;
    localparam STATUS_REG_ADDR   = 8'h04;
    
    // States for USB detection
    localparam IDLE = 2'b00;
    localparam WAIT_STABLE = 2'b01;
    localparam DETECT = 2'b10;
    localparam COMPLETE = 2'b11;
    
    // Internal registers
    reg [31:0] ctrl_reg;
    reg [31:0] status_reg;
    
    // Control/Status Bits
    wire detect_en = ctrl_reg[0];
    reg low_speed;
    reg full_speed;
    reg no_device;
    reg chirp_detected;
    reg [1:0] detection_state;
    
    // Additional signals
    reg [9:0] stability_counter;
    reg prev_dp, prev_dm;
    
    // Pipeline registers for AXI logic
    reg s_axi_awvalid_r;
    reg s_axi_wvalid_r;
    reg [7:0] s_axi_awaddr_r;
    reg [31:0] s_axi_wdata_r;
    reg [3:0] s_axi_wstrb_r;
    reg s_axi_arvalid_r;
    reg [7:0] s_axi_araddr_r;
    
    // Pipeline registers for response channels
    reg write_transaction_valid;
    reg read_transaction_valid;
    
    // Pipeline registers for USB detection
    reg dp_stable, dm_stable;
    reg [9:0] stability_counter_next;
    reg detect_complete;
    
    // First stage pipeline for AXI signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awvalid_r <= 1'b0;
            s_axi_wvalid_r <= 1'b0;
            s_axi_awaddr_r <= 8'h0;
            s_axi_wdata_r <= 32'h0;
            s_axi_wstrb_r <= 4'h0;
            s_axi_arvalid_r <= 1'b0;
            s_axi_araddr_r <= 8'h0;
        end else begin
            s_axi_awvalid_r <= s_axi_awvalid;
            s_axi_wvalid_r <= s_axi_wvalid;
            s_axi_awaddr_r <= s_axi_awaddr;
            s_axi_wdata_r <= s_axi_wdata;
            s_axi_wstrb_r <= s_axi_wstrb;
            s_axi_arvalid_r <= s_axi_arvalid;
            s_axi_araddr_r <= s_axi_araddr;
        end
    end
    
    // Write address channel logic - optimized
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
        end else begin
            if (~s_axi_awready && s_axi_awvalid_r) begin
                s_axi_awready <= 1'b1;
            end else begin
                s_axi_awready <= 1'b0;
            end
        end
    end
    
    // Write data channel logic - pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_wready <= 1'b0;
            write_transaction_valid <= 1'b0;
        end else begin
            if (~s_axi_wready && s_axi_wvalid_r && s_axi_awvalid_r) begin
                s_axi_wready <= 1'b1;
                write_transaction_valid <= 1'b1;
            end else begin
                s_axi_wready <= 1'b0;
                write_transaction_valid <= 1'b0;
            end
        end
    end
    
    // Write data channel logic - pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_reg <= 32'h0;
        end else if (write_transaction_valid) begin
            if (s_axi_awaddr_r == CTRL_REG_ADDR) begin
                // Write to control register with byte enables
                if (s_axi_wstrb_r[0]) ctrl_reg[7:0] <= s_axi_wdata_r[7:0];
                if (s_axi_wstrb_r[1]) ctrl_reg[15:8] <= s_axi_wdata_r[15:8];
                if (s_axi_wstrb_r[2]) ctrl_reg[23:16] <= s_axi_wdata_r[23:16];
                if (s_axi_wstrb_r[3]) ctrl_reg[31:24] <= s_axi_wdata_r[31:24];
            end
        end
    end
    
    // Write response channel logic - pipelined
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid <= 1'b0;
            s_axi_bresp <= 2'b00; // OKAY response
        end else begin
            if (write_transaction_valid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp <= 2'b00; // OKAY response
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end
    
    // Read address channel logic - pipelined
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            read_transaction_valid <= 1'b0;
        end else begin
            if (~s_axi_arready && s_axi_arvalid_r) begin
                s_axi_arready <= 1'b1;
                read_transaction_valid <= 1'b1;
            end else begin
                s_axi_arready <= 1'b0;
                read_transaction_valid <= 1'b0;
            end
        end
    end
    
    // Prepare status register for reads - pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            status_reg <= 32'h0;
        end else begin
            status_reg <= {26'b0, detection_state, chirp_detected, no_device, full_speed, low_speed};
        end
    end
    
    // Read data channel logic - pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_rvalid <= 1'b0;
            s_axi_rresp <= 2'b00; // OKAY response
            s_axi_rdata <= 32'h0;
        end else begin
            if (read_transaction_valid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp <= 2'b00; // OKAY response
                
                case (s_axi_araddr_r)
                    CTRL_REG_ADDR: s_axi_rdata <= ctrl_reg;
                    STATUS_REG_ADDR: s_axi_rdata <= status_reg;
                    default: s_axi_rdata <= 32'h0;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end
    
    // USB signal synchronization - pipeline stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            prev_dp <= 1'b0;
            prev_dm <= 1'b0;
            dp_stable <= 1'b0;
            dm_stable <= 1'b0;
        end else begin
            prev_dp <= dp;
            prev_dm <= dm;
            dp_stable <= (dp == prev_dp);
            dm_stable <= (dm == prev_dm);
        end
    end
    
    // Stability counter logic - pipeline stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stability_counter <= 10'd0;
            stability_counter_next <= 10'd0;
            detect_complete <= 1'b0;
        end else begin
            case (detection_state)
                WAIT_STABLE: begin
                    if (dp_stable && dm_stable) begin
                        stability_counter_next <= stability_counter + 10'd1;
                        detect_complete <= (stability_counter >= 10'd499); // One cycle earlier
                    end else begin
                        stability_counter_next <= 10'd0;
                        detect_complete <= 1'b0;
                    end
                end
                default: begin
                    stability_counter_next <= 10'd0;
                    detect_complete <= 1'b0;
                end
            endcase
            
            stability_counter <= stability_counter_next;
        end
    end
    
    // USB speed detection core logic - pipelined final stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            detection_state <= IDLE;
            low_speed <= 1'b0;
            full_speed <= 1'b0;
            no_device <= 1'b1;
            chirp_detected <= 1'b0;
        end else begin
            case (detection_state)
                IDLE: begin
                    if (detect_en) begin
                        detection_state <= WAIT_STABLE;
                    end
                end
                WAIT_STABLE: begin
                    if (detect_complete) begin
                        detection_state <= DETECT;
                    end
                end
                DETECT: begin
                    no_device <= !(dp || dm);
                    full_speed <= dp && !dm;
                    low_speed <= !dp && dm;
                    chirp_detected <= dp && dm;
                    detection_state <= COMPLETE;
                end
                COMPLETE: begin
                    if (!detect_en)
                        detection_state <= IDLE;
                end
            endcase
        end
    end

endmodule