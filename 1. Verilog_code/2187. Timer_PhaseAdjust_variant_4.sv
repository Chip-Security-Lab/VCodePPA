//SystemVerilog
module Timer_PhaseAdjust (
    input wire clk,
    input wire rst_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [7:0] s_axil_awaddr,
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
    input wire [7:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output wire s_axil_arready,
    
    // Read Data Channel
    output wire [31:0] s_axil_rdata,
    output wire [1:0] s_axil_rresp,
    output wire s_axil_rvalid,
    input wire s_axil_rready,
    
    // Timer Output
    output wire timer_pulse
);
    // Register addresses
    localparam PHASE_REG_ADDR  = 8'h00;
    localparam STATUS_REG_ADDR = 8'h04;
    localparam CTRL_REG_ADDR   = 8'h08;
    
    // AXI response codes
    localparam RESP_OKAY = 2'b00;
    localparam RESP_ERR  = 2'b10;
    
    // Internal registers with pipeline stages
    reg [3:0] cnt_stage1;
    reg [3:0] cnt_stage2;
    reg [3:0] phase_reg_stage1;
    reg [3:0] phase_reg_stage2;
    reg timer_enable_stage1;
    reg timer_enable_stage2;
    
    // Pulse generation pipeline
    reg compare_stage1;
    reg compare_stage2;
    reg out_pulse_stage1;
    reg out_pulse_stage2;
    reg out_pulse_stage3;
    
    // AXI pipeline stages
    // Write path
    reg write_addr_valid_stage1;
    reg write_addr_valid_stage2;
    reg write_data_valid_stage1;
    reg write_data_valid_stage2;
    reg [7:0] write_addr_stage1;
    reg [7:0] write_addr_stage2;
    reg [31:0] write_data_stage1;
    reg [31:0] write_data_stage2;
    reg write_resp_valid_stage1;
    reg write_resp_valid_stage2;
    
    // Read path
    reg read_addr_valid_stage1;
    reg read_addr_valid_stage2;
    reg [7:0] read_addr_stage1;
    reg [7:0] read_addr_stage2;
    reg [31:0] read_data_stage1;
    reg [31:0] read_data_stage2;
    reg read_resp_valid_stage1;
    reg read_resp_valid_stage2;
    
    // AXI interface outputs
    assign s_axil_awready = ~write_addr_valid_stage1;
    assign s_axil_wready = ~write_data_valid_stage1;
    assign s_axil_bresp = RESP_OKAY;
    assign s_axil_bvalid = write_resp_valid_stage2;
    assign s_axil_arready = ~read_addr_valid_stage1;
    assign s_axil_rdata = read_data_stage2;
    assign s_axil_rresp = RESP_OKAY;
    assign s_axil_rvalid = read_resp_valid_stage2;
    
    // Timer output
    assign timer_pulse = out_pulse_stage3;
    
    // Write address channel pipeline - Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_addr_valid_stage1 <= 1'b0;
            write_addr_stage1 <= 8'h0;
        end else if (s_axil_awvalid && s_axil_awready) begin
            write_addr_valid_stage1 <= 1'b1;
            write_addr_stage1 <= s_axil_awaddr;
        end else if (write_data_valid_stage2 && write_resp_valid_stage2 && s_axil_bready) begin
            write_addr_valid_stage1 <= 1'b0;
        end
    end
    
    // Write address channel pipeline - Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_addr_valid_stage2 <= 1'b0;
            write_addr_stage2 <= 8'h0;
        end else begin
            write_addr_valid_stage2 <= write_addr_valid_stage1;
            write_addr_stage2 <= write_addr_stage1;
        end
    end
    
    // Write data channel pipeline - Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_data_valid_stage1 <= 1'b0;
            write_data_stage1 <= 32'h0;
        end else if (s_axil_wvalid && s_axil_wready) begin
            write_data_valid_stage1 <= 1'b1;
            write_data_stage1 <= s_axil_wdata;
        end else if (write_addr_valid_stage2 && write_resp_valid_stage2 && s_axil_bready) begin
            write_data_valid_stage1 <= 1'b0;
        end
    end
    
    // Write data channel pipeline - Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_data_valid_stage2 <= 1'b0;
            write_data_stage2 <= 32'h0;
        end else begin
            write_data_valid_stage2 <= write_data_valid_stage1;
            write_data_stage2 <= write_data_stage1;
        end
    end
    
    // Write response channel pipeline - Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_resp_valid_stage1 <= 1'b0;
        end else if (write_addr_valid_stage2 && write_data_valid_stage2 && !write_resp_valid_stage1) begin
            write_resp_valid_stage1 <= 1'b1;
        end else if (write_resp_valid_stage2 && s_axil_bready) begin
            write_resp_valid_stage1 <= 1'b0;
        end
    end
    
    // Write response channel pipeline - Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_resp_valid_stage2 <= 1'b0;
        end else begin
            write_resp_valid_stage2 <= write_resp_valid_stage1;
        end
    end
    
    // Read address channel pipeline - Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_addr_valid_stage1 <= 1'b0;
            read_addr_stage1 <= 8'h0;
        end else if (s_axil_arvalid && s_axil_arready) begin
            read_addr_valid_stage1 <= 1'b1;
            read_addr_stage1 <= s_axil_araddr;
        end else if (read_resp_valid_stage2 && s_axil_rready) begin
            read_addr_valid_stage1 <= 1'b0;
        end
    end
    
    // Read address channel pipeline - Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_addr_valid_stage2 <= 1'b0;
            read_addr_stage2 <= 8'h0;
        end else begin
            read_addr_valid_stage2 <= read_addr_valid_stage1;
            read_addr_stage2 <= read_addr_stage1;
        end
    end
    
    // Read data channel pipeline - Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_resp_valid_stage1 <= 1'b0;
            read_data_stage1 <= 32'h0;
        end else if (read_addr_valid_stage2 && !read_resp_valid_stage1) begin
            read_resp_valid_stage1 <= 1'b1;
            
            case (read_addr_stage2)
                PHASE_REG_ADDR: read_data_stage1 <= {28'h0, phase_reg_stage2};
                STATUS_REG_ADDR: read_data_stage1 <= {31'h0, out_pulse_stage3};
                CTRL_REG_ADDR: read_data_stage1 <= {31'h0, timer_enable_stage2};
                default: read_data_stage1 <= 32'h0;
            endcase
        end else if (read_resp_valid_stage2 && s_axil_rready) begin
            read_resp_valid_stage1 <= 1'b0;
        end
    end
    
    // Read data channel pipeline - Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            read_resp_valid_stage2 <= 1'b0;
            read_data_stage2 <= 32'h0;
        end else begin
            read_resp_valid_stage2 <= read_resp_valid_stage1;
            read_data_stage2 <= read_data_stage1;
        end
    end
    
    // Register write logic pipeline - Stage 1 and Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_reg_stage1 <= 4'h0;
            phase_reg_stage2 <= 4'h0;
            timer_enable_stage1 <= 1'b0;
            timer_enable_stage2 <= 1'b0;
        end else begin
            // Pipeline stage 2 follows stage 1
            phase_reg_stage2 <= phase_reg_stage1;
            timer_enable_stage2 <= timer_enable_stage1;
            
            // Update stage 1 based on write operations
            if (write_addr_valid_stage2 && write_data_valid_stage2 && !write_resp_valid_stage1) begin
                case (write_addr_stage2)
                    PHASE_REG_ADDR: phase_reg_stage1 <= write_data_stage2[3:0];
                    CTRL_REG_ADDR: timer_enable_stage1 <= write_data_stage2[0];
                    default: ; // No action for other addresses
                endcase
            end
        end
    end
    
    // Timer counter pipeline - Stage 1
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage1 <= 4'h0;
        end else if (timer_enable_stage2) begin
            cnt_stage1 <= cnt_stage1 + 4'h1;
        end
    end
    
    // Timer counter pipeline - Stage 2
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt_stage2 <= 4'h0;
            compare_stage1 <= 1'b0;
        end else begin
            cnt_stage2 <= cnt_stage1;
            // First stage of comparison
            compare_stage1 <= (cnt_stage1 == phase_reg_stage2);
        end
    end
    
    // Pulse generation pipeline - Stages 1, 2, 3
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compare_stage2 <= 1'b0;
            out_pulse_stage1 <= 1'b0;
            out_pulse_stage2 <= 1'b0;
            out_pulse_stage3 <= 1'b0;
        end else begin
            // Stage 2 of comparison
            compare_stage2 <= compare_stage1;
            
            // Generate pulse in stages
            out_pulse_stage1 <= timer_enable_stage2 && compare_stage2;
            out_pulse_stage2 <= out_pulse_stage1;
            out_pulse_stage3 <= out_pulse_stage2;
        end
    end
    
endmodule