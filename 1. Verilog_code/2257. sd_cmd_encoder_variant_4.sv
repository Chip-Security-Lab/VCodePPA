//SystemVerilog
module sd_cmd_encoder (
    input wire clk,
    input wire reset_n,
    
    // AXI4-Lite Slave Interface
    // Write Address Channel
    input wire [31:0] s_axil_awaddr,
    input wire s_axil_awvalid,
    output reg s_axil_awready,
    
    // Write Data Channel
    input wire [31:0] s_axil_wdata,
    input wire [3:0] s_axil_wstrb,
    input wire s_axil_wvalid,
    output reg s_axil_wready,
    
    // Write Response Channel
    output reg [1:0] s_axil_bresp,
    output reg s_axil_bvalid,
    input wire s_axil_bready,
    
    // Read Address Channel
    input wire [31:0] s_axil_araddr,
    input wire s_axil_arvalid,
    output reg s_axil_arready,
    
    // Read Data Channel
    output reg [31:0] s_axil_rdata,
    output reg [1:0] s_axil_rresp,
    output reg s_axil_rvalid,
    input wire s_axil_rready,
    
    // SD Command Output
    output reg cmd_out
);

    // Register address map
    localparam CMD_CTRL_REG_ADDR   = 4'h0; // Bit 0: cmd_en
    localparam CMD_REG_ADDR        = 4'h4; // Bits 5:0: cmd
    localparam ARG_REG_ADDR        = 4'h8; // Bits 31:0: arg
    localparam STATUS_REG_ADDR     = 4'hC; // Bit 0: cmd_active

    // Internal registers
    reg cmd_en;
    reg [5:0] cmd;
    reg [31:0] arg;
    
    // Pipeline stage registers
    reg [47:0] shift_reg_stage1;
    reg [47:0] shift_reg_stage2;
    reg [5:0] cnt_stage1;
    reg [5:0] cnt_stage2;
    reg cmd_active_stage1;
    reg cmd_active_stage2;
    
    // Write transaction FSM states
    localparam WRITE_IDLE = 2'b00;
    localparam WRITE_ADDR = 2'b01;
    localparam WRITE_DATA = 2'b10;
    localparam WRITE_RESP = 2'b11;
    
    reg [1:0] write_state;
    reg [3:0] write_addr;
    
    // Read transaction FSM states
    localparam READ_IDLE = 2'b00;
    localparam READ_ADDR = 2'b01;
    localparam READ_DATA = 2'b10;
    
    reg [1:0] read_state;
    reg [3:0] read_addr;

    // Write channel FSM
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            write_state <= WRITE_IDLE;
            write_addr <= 4'h0;
            s_axil_awready <= 1'b0;
            s_axil_wready <= 1'b0;
            s_axil_bvalid <= 1'b0;
            s_axil_bresp <= 2'b00;
            cmd_en <= 1'b0;
            cmd <= 6'b0;
            arg <= 32'b0;
        end
        else begin
            case (write_state)
                WRITE_IDLE: begin
                    s_axil_awready <= 1'b1;
                    s_axil_wready <= 1'b0;
                    s_axil_bvalid <= 1'b0;
                    
                    if (s_axil_awvalid && s_axil_awready) begin
                        write_addr <= s_axil_awaddr[5:2];
                        s_axil_awready <= 1'b0;
                        s_axil_wready <= 1'b1;
                        write_state <= WRITE_ADDR;
                    end
                end
                
                WRITE_ADDR: begin
                    if (s_axil_wvalid && s_axil_wready) begin
                        s_axil_wready <= 1'b0;
                        s_axil_bvalid <= 1'b1;
                        s_axil_bresp <= 2'b00; // OKAY response
                        
                        case (write_addr)
                            CMD_CTRL_REG_ADDR: cmd_en <= s_axil_wdata[0];
                            CMD_REG_ADDR: cmd <= s_axil_wdata[5:0];
                            ARG_REG_ADDR: arg <= s_axil_wdata;
                            default: s_axil_bresp <= 2'b10; // SLVERR for invalid address
                        endcase
                        
                        write_state <= WRITE_RESP;
                    end
                end
                
                WRITE_RESP: begin
                    if (s_axil_bready && s_axil_bvalid) begin
                        s_axil_bvalid <= 1'b0;
                        write_state <= WRITE_IDLE;
                        s_axil_awready <= 1'b1;
                    end
                end
                
                default: write_state <= WRITE_IDLE;
            endcase
            
            // Auto-clear cmd_en after one cycle
            if (cmd_en) cmd_en <= 1'b0;
        end
    end

    // Read channel FSM
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            read_state <= READ_IDLE;
            read_addr <= 4'h0;
            s_axil_arready <= 1'b0;
            s_axil_rvalid <= 1'b0;
            s_axil_rresp <= 2'b00;
            s_axil_rdata <= 32'h0;
        end
        else begin
            case (read_state)
                READ_IDLE: begin
                    s_axil_arready <= 1'b1;
                    s_axil_rvalid <= 1'b0;
                    
                    if (s_axil_arvalid && s_axil_arready) begin
                        read_addr <= s_axil_araddr[5:2];
                        s_axil_arready <= 1'b0;
                        read_state <= READ_ADDR;
                    end
                end
                
                READ_ADDR: begin
                    s_axil_rvalid <= 1'b1;
                    s_axil_rresp <= 2'b00; // OKAY response
                    
                    case (read_addr)
                        CMD_CTRL_REG_ADDR: s_axil_rdata <= {31'b0, cmd_en};
                        CMD_REG_ADDR: s_axil_rdata <= {26'b0, cmd};
                        ARG_REG_ADDR: s_axil_rdata <= arg;
                        STATUS_REG_ADDR: s_axil_rdata <= {31'b0, cmd_active_stage2};
                        default: begin
                            s_axil_rdata <= 32'h0;
                            s_axil_rresp <= 2'b10; // SLVERR for invalid address
                        end
                    endcase
                    
                    read_state <= READ_DATA;
                end
                
                READ_DATA: begin
                    if (s_axil_rready && s_axil_rvalid) begin
                        s_axil_rvalid <= 1'b0;
                        read_state <= READ_IDLE;
                        s_axil_arready <= 1'b1;
                    end
                end
                
                default: read_state <= READ_IDLE;
            endcase
        end
    end

    // Stage 1: Command preparation and initial counting
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg_stage1 <= 48'b0;
            cnt_stage1 <= 6'b0;
            cmd_active_stage1 <= 1'b0;
        end
        else if (cmd_en) begin
            shift_reg_stage1 <= {1'b0, cmd, arg, 7'h01};
            cnt_stage1 <= 47;
            cmd_active_stage1 <= 1'b1;
        end
        else if (cnt_stage1 > 0) begin
            shift_reg_stage1 <= shift_reg_stage1;
            cnt_stage1 <= cnt_stage1 - 1;
            cmd_active_stage1 <= 1'b1;
        end
        else begin
            cmd_active_stage1 <= 1'b0;
        end
    end
    
    // Stage 2: Bit selection and output preparation
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg_stage2 <= 48'b0;
            cnt_stage2 <= 6'b0;
            cmd_active_stage2 <= 1'b0;
        end
        else begin
            shift_reg_stage2 <= shift_reg_stage1;
            cnt_stage2 <= cnt_stage1;
            cmd_active_stage2 <= cmd_active_stage1;
        end
    end
    
    // Output stage: Final bit output
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            cmd_out <= 1'b1; // Default idle state for CMD line is high
        end
        else if (cmd_active_stage2) begin
            cmd_out <= shift_reg_stage2[cnt_stage2];
        end
        else begin
            cmd_out <= 1'b1; // Return to idle state
        end
    end

endmodule