//SystemVerilog
//-----------------------------------------------------------------------------
// File: packet_buffer_top.v
// Description: Top-level module for packet buffer system with pipelined paths
// Standard: IEEE 1364-2005
//-----------------------------------------------------------------------------

module packet_buffer_top #(
    parameter DW = 8
)(
    input  wire           clk,
    input  wire           rst_n,
    input  wire [DW-1:0]  din,
    input  wire           din_valid,
    output wire [DW-1:0]  dout,
    output wire           pkt_valid
);

    // Internal signals for connecting submodules
    wire           delimiter_detected;
    wire           delimiter_detected_pipe;
    wire [2:0]     fsm_state;
    wire           load_output;
    wire           set_valid;
    wire           load_output_pipe;
    wire           set_valid_pipe;
    wire [DW-1:0]  din_pipe;
    wire           din_valid_pipe;

    // Parameter for the delimiter value
    localparam [7:0] DELIMITER_VALUE = 8'hFF;

    // Pipeline registers for input signals
    pipeline_register #(
        .DW(DW+1)
    ) u_input_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .data_in({din_valid, din}),
        .data_out({din_valid_pipe, din_pipe})
    );

    // Pipeline register for control signals
    pipeline_register #(
        .DW(1)
    ) u_delimiter_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .data_in(delimiter_detected),
        .data_out(delimiter_detected_pipe)
    );
    
    // Pipeline register for output control signals
    pipeline_register #(
        .DW(2)
    ) u_output_ctrl_pipeline (
        .clk(clk),
        .rst_n(rst_n),
        .data_in({load_output, set_valid}),
        .data_out({load_output_pipe, set_valid_pipe})
    );

    // Submodule instantiations
    packet_detector #(
        .DW(DW),
        .DELIMITER(DELIMITER_VALUE)
    ) u_packet_detector (
        .clk                (clk),
        .rst_n              (rst_n),
        .din                (din),
        .din_valid          (din_valid),
        .delimiter_detected (delimiter_detected)
    );

    packet_fsm u_packet_fsm (
        .clk                (clk),
        .rst_n              (rst_n),
        .din_valid          (din_valid_pipe),
        .delimiter_detected (delimiter_detected_pipe),
        .state              (fsm_state),
        .load_output        (load_output),
        .set_valid          (set_valid)
    );
    
    packet_output #(
        .DW(DW)
    ) u_packet_output (
        .clk         (clk),
        .rst_n       (rst_n),
        .din         (din_pipe),
        .load_output (load_output_pipe),
        .set_valid   (set_valid_pipe),
        .dout        (dout),
        .pkt_valid   (pkt_valid)
    );

endmodule

//-----------------------------------------------------------------------------
// File: pipeline_register.v
// Description: Generic pipeline register for critical path cutting
//-----------------------------------------------------------------------------

module pipeline_register #(
    parameter DW = 8
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire [DW-1:0] data_in,
    output reg  [DW-1:0] data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= {DW{1'b0}};
        end else begin
            data_out <= data_in;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// File: packet_detector.v
// Description: Detects packet delimiter in input data stream
//-----------------------------------------------------------------------------

module packet_detector #(
    parameter DW = 8,
    parameter [7:0] DELIMITER = 8'hFF
)(
    input  wire           clk,
    input  wire           rst_n,
    input  wire [DW-1:0]  din,
    input  wire           din_valid,
    output reg            delimiter_detected
);

    // Pipelined comparison logic
    reg             din_valid_r;
    reg [DW-1:0]    din_r;
    reg             compare_result;
    
    // Stage 1: Register inputs to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_valid_r <= 1'b0;
            din_r <= {DW{1'b0}};
        end else begin
            din_valid_r <= din_valid;
            din_r <= din;
        end
    end
    
    // Stage 2: Perform comparison
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            compare_result <= 1'b0;
        end else begin
            compare_result <= (din_r == DELIMITER);
        end
    end
    
    // Stage 3: Generate final result
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            delimiter_detected <= 1'b0;
        end else begin
            delimiter_detected <= din_valid_r && compare_result;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// File: packet_fsm.v
// Description: FSM controller for packet processing
//-----------------------------------------------------------------------------

module packet_fsm (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       din_valid,
    input  wire       delimiter_detected,
    output reg [2:0]  state,
    output reg        load_output,
    output reg        set_valid
);

    // FSM states
    localparam [2:0] 
        IDLE    = 3'd0,
        CAPTURE = 3'd1,
        PROCESS = 3'd2;

    // Internal pipeline registers
    reg [2:0] next_state;
    reg       next_load_output;
    reg       next_set_valid;

    // Stage 1: Next state logic (combinational)
    always @(*) begin
        // Default values
        next_load_output = 1'b0;
        next_set_valid = 1'b0;
        next_state = state;
        
        case (state)
            IDLE: begin
                if (delimiter_detected) begin
                    next_state = CAPTURE;
                end
            end
            
            CAPTURE: begin
                next_load_output = 1'b1;
                next_set_valid = 1'b1;
                next_state = PROCESS;
            end
            
            PROCESS: begin
                if (!din_valid) begin
                    next_state = IDLE;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    // Stage 2: Register the state and outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            load_output <= 1'b0;
            set_valid <= 1'b0;
        end else begin
            state <= next_state;
            load_output <= next_load_output;
            set_valid <= next_set_valid;
        end
    end

endmodule

//-----------------------------------------------------------------------------
// File: packet_output.v
// Description: Output stage for packet data with pipelined logic
//-----------------------------------------------------------------------------

module packet_output #(
    parameter DW = 8
)(
    input  wire          clk,
    input  wire          rst_n,
    input  wire [DW-1:0] din,
    input  wire          load_output,
    input  wire          set_valid,
    output reg  [DW-1:0] dout,
    output reg           pkt_valid
);

    // Internal pipeline registers
    reg [DW-1:0] dout_next;
    reg          pkt_valid_next;
    
    // Stage 1: Calculate next values (break long combinational path)
    always @(*) begin
        dout_next = dout;
        pkt_valid_next = pkt_valid;
        
        if (load_output) begin
            dout_next = din;
        end
        
        if (set_valid) begin
            pkt_valid_next = 1'b1;
        end else if (!load_output) begin
            pkt_valid_next = 1'b0;
        end
    end
    
    // Stage 2: Register the outputs
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {DW{1'b0}};
            pkt_valid <= 1'b0;
        end else begin
            dout <= dout_next;
            pkt_valid <= pkt_valid_next;
        end
    end

endmodule