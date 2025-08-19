//SystemVerilog
module cam_7 (
    // AXI4-Lite Interface Signals
    input wire ACLK,
    input wire ARESETn,
    
    // Write Address Channel
    input wire [31:0] AWADDR,
    input wire AWVALID,
    output reg AWREADY,
    
    // Write Data Channel
    input wire [31:0] WDATA,
    input wire [3:0] WSTRB,
    input wire WVALID,
    output reg WREADY,
    
    // Write Response Channel
    output reg [1:0] BRESP,
    output reg BVALID,
    input wire BREADY,
    
    // Read Address Channel
    input wire [31:0] ARADDR,
    input wire ARVALID,
    output reg ARREADY,
    
    // Read Data Channel
    output reg [31:0] RDATA,
    output reg [1:0] RRESP,
    output reg RVALID,
    input wire RREADY,
    
    // Original CAM signals
    output reg match,
    output reg [7:0] priority_data
);

    reg [7:0] high_priority, low_priority;
    reg [1:0] state;
    reg [31:0] addr_reg;
    
    localparam IDLE = 2'b00;
    localparam WRITE = 2'b01;
    localparam READ = 2'b10;
    
    // Write FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            state <= IDLE;
            high_priority <= 8'b0;
            low_priority <= 8'b0;
            match <= 1'b0;
            priority_data <= 8'b0;
            AWREADY <= 1'b0;
            WREADY <= 1'b0;
            BVALID <= 1'b0;
            BRESP <= 2'b00;
        end else begin
            case (state)
                IDLE: begin
                    AWREADY <= 1'b1;
                    WREADY <= 1'b0;
                    BVALID <= 1'b0;
                    if (AWVALID) begin
                        addr_reg <= AWADDR;
                        state <= WRITE;
                        AWREADY <= 1'b0;
                        WREADY <= 1'b1;
                    end
                end
                WRITE: begin
                    if (WVALID) begin
                        case (addr_reg[1:0])
                            2'b00: high_priority <= WDATA[7:0];
                            2'b01: low_priority <= WDATA[7:0];
                        endcase
                        WREADY <= 1'b0;
                        BVALID <= 1'b1;
                        BRESP <= 2'b00;
                        if (BREADY) begin
                            BVALID <= 1'b0;
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
    
    // Read FSM
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            ARREADY <= 1'b1;
            RVALID <= 1'b0;
            RDATA <= 32'b0;
            RRESP <= 2'b00;
        end else begin
            if (ARVALID && ARREADY) begin
                ARREADY <= 1'b0;
                RVALID <= 1'b1;
                case (ARADDR[1:0])
                    2'b00: RDATA <= {24'b0, high_priority};
                    2'b01: RDATA <= {24'b0, low_priority};
                    2'b10: RDATA <= {31'b0, match};
                    2'b11: RDATA <= {24'b0, priority_data};
                endcase
                RRESP <= 2'b00;
            end
            if (RVALID && RREADY) begin
                RVALID <= 1'b0;
                ARREADY <= 1'b1;
            end
        end
    end
    
    // CAM matching logic
    always @(posedge ACLK) begin
        if (high_priority == RDATA[7:0]) begin
            priority_data <= high_priority;
            match <= 1'b1;
        end else if (low_priority == RDATA[7:0]) begin
            priority_data <= low_priority;
            match <= 1'b1;
        end else begin
            match <= 1'b0;
        end
    end
endmodule