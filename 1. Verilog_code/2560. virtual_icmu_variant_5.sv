//SystemVerilog
module virtual_icmu #(
    parameter GUESTS = 2,
    parameter INTS_PER_GUEST = 8
)(
    input clk, rst_n,
    input [INTS_PER_GUEST*GUESTS-1:0] phys_int,
    input [1:0] active_guest,
    input guest_switch_req,
    output reg [2:0] guest_int_id [0:GUESTS-1],
    output reg [GUESTS-1:0] int_pending_guest,
    output reg guest_switch_done
);
    reg [INTS_PER_GUEST-1:0] virt_int_pending [0:GUESTS-1];
    reg [INTS_PER_GUEST-1:0] virt_int_mask [0:GUESTS-1];
    reg [2:0] current_state;
    integer g, i;
    
    // Gray code encoding for states
    localparam IDLE = 3'b000;
    localparam SAVE_CONTEXT = 3'b001;
    localparam SWITCH_PENDING = 3'b011;
    localparam RESTORE_CONTEXT = 3'b010;
    localparam SWITCH_DONE = 3'b110;
    
    // LUT for priority encoding
    reg [2:0] priority_lut [0:255];
    initial begin
        priority_lut[0] = 3'd0;
        priority_lut[1] = 3'd0;
        priority_lut[2] = 3'd1;
        priority_lut[3] = 3'd1;
        priority_lut[4] = 3'd2;
        priority_lut[5] = 3'd2;
        priority_lut[6] = 3'd2;
        priority_lut[7] = 3'd2;
        priority_lut[8] = 3'd3;
        priority_lut[9] = 3'd3;
        priority_lut[10] = 3'd3;
        priority_lut[11] = 3'd3;
        priority_lut[12] = 3'd3;
        priority_lut[13] = 3'd3;
        priority_lut[14] = 3'd3;
        priority_lut[15] = 3'd3;
        priority_lut[16] = 3'd4;
        priority_lut[17] = 3'd4;
        priority_lut[18] = 3'd4;
        priority_lut[19] = 3'd4;
        priority_lut[20] = 3'd4;
        priority_lut[21] = 3'd4;
        priority_lut[22] = 3'd4;
        priority_lut[23] = 3'd4;
        priority_lut[24] = 3'd4;
        priority_lut[25] = 3'd4;
        priority_lut[26] = 3'd4;
        priority_lut[27] = 3'd4;
        priority_lut[28] = 3'd4;
        priority_lut[29] = 3'd4;
        priority_lut[30] = 3'd4;
        priority_lut[31] = 3'd4;
        priority_lut[32] = 3'd5;
        priority_lut[33] = 3'd5;
        priority_lut[34] = 3'd5;
        priority_lut[35] = 3'd5;
        priority_lut[36] = 3'd5;
        priority_lut[37] = 3'd5;
        priority_lut[38] = 3'd5;
        priority_lut[39] = 3'd5;
        priority_lut[40] = 3'd5;
        priority_lut[41] = 3'd5;
        priority_lut[42] = 3'd5;
        priority_lut[43] = 3'd5;
        priority_lut[44] = 3'd5;
        priority_lut[45] = 3'd5;
        priority_lut[46] = 3'd5;
        priority_lut[47] = 3'd5;
        priority_lut[48] = 3'd5;
        priority_lut[49] = 3'd5;
        priority_lut[50] = 3'd5;
        priority_lut[51] = 3'd5;
        priority_lut[52] = 3'd5;
        priority_lut[53] = 3'd5;
        priority_lut[54] = 3'd5;
        priority_lut[55] = 3'd5;
        priority_lut[56] = 3'd5;
        priority_lut[57] = 3'd5;
        priority_lut[58] = 3'd5;
        priority_lut[59] = 3'd5;
        priority_lut[60] = 3'd5;
        priority_lut[61] = 3'd5;
        priority_lut[62] = 3'd5;
        priority_lut[63] = 3'd5;
        priority_lut[64] = 3'd6;
        priority_lut[65] = 3'd6;
        priority_lut[66] = 3'd6;
        priority_lut[67] = 3'd6;
        priority_lut[68] = 3'd6;
        priority_lut[69] = 3'd6;
        priority_lut[70] = 3'd6;
        priority_lut[71] = 3'd6;
        priority_lut[72] = 3'd6;
        priority_lut[73] = 3'd6;
        priority_lut[74] = 3'd6;
        priority_lut[75] = 3'd6;
        priority_lut[76] = 3'd6;
        priority_lut[77] = 3'd6;
        priority_lut[78] = 3'd6;
        priority_lut[79] = 3'd6;
        priority_lut[80] = 3'd6;
        priority_lut[81] = 3'd6;
        priority_lut[82] = 3'd6;
        priority_lut[83] = 3'd6;
        priority_lut[84] = 3'd6;
        priority_lut[85] = 3'd6;
        priority_lut[86] = 3'd6;
        priority_lut[87] = 3'd6;
        priority_lut[88] = 3'd6;
        priority_lut[89] = 3'd6;
        priority_lut[90] = 3'd6;
        priority_lut[91] = 3'd6;
        priority_lut[92] = 3'd6;
        priority_lut[93] = 3'd6;
        priority_lut[94] = 3'd6;
        priority_lut[95] = 3'd6;
        priority_lut[96] = 3'd6;
        priority_lut[97] = 3'd6;
        priority_lut[98] = 3'd6;
        priority_lut[99] = 3'd6;
        priority_lut[100] = 3'd6;
        priority_lut[101] = 3'd6;
        priority_lut[102] = 3'd6;
        priority_lut[103] = 3'd6;
        priority_lut[104] = 3'd6;
        priority_lut[105] = 3'd6;
        priority_lut[106] = 3'd6;
        priority_lut[107] = 3'd6;
        priority_lut[108] = 3'd6;
        priority_lut[109] = 3'd6;
        priority_lut[110] = 3'd6;
        priority_lut[111] = 3'd6;
        priority_lut[112] = 3'd6;
        priority_lut[113] = 3'd6;
        priority_lut[114] = 3'd6;
        priority_lut[115] = 3'd6;
        priority_lut[116] = 3'd6;
        priority_lut[117] = 3'd6;
        priority_lut[118] = 3'd6;
        priority_lut[119] = 3'd6;
        priority_lut[120] = 3'd6;
        priority_lut[121] = 3'd6;
        priority_lut[122] = 3'd6;
        priority_lut[123] = 3'd6;
        priority_lut[124] = 3'd6;
        priority_lut[125] = 3'd6;
        priority_lut[126] = 3'd6;
        priority_lut[127] = 3'd6;
        priority_lut[128] = 3'd7;
        priority_lut[129] = 3'd7;
        priority_lut[130] = 3'd7;
        priority_lut[131] = 3'd7;
        priority_lut[132] = 3'd7;
        priority_lut[133] = 3'd7;
        priority_lut[134] = 3'd7;
        priority_lut[135] = 3'd7;
        priority_lut[136] = 3'd7;
        priority_lut[137] = 3'd7;
        priority_lut[138] = 3'd7;
        priority_lut[139] = 3'd7;
        priority_lut[140] = 3'd7;
        priority_lut[141] = 3'd7;
        priority_lut[142] = 3'd7;
        priority_lut[143] = 3'd7;
        priority_lut[144] = 3'd7;
        priority_lut[145] = 3'd7;
        priority_lut[146] = 3'd7;
        priority_lut[147] = 3'd7;
        priority_lut[148] = 3'd7;
        priority_lut[149] = 3'd7;
        priority_lut[150] = 3'd7;
        priority_lut[151] = 3'd7;
        priority_lut[152] = 3'd7;
        priority_lut[153] = 3'd7;
        priority_lut[154] = 3'd7;
        priority_lut[155] = 3'd7;
        priority_lut[156] = 3'd7;
        priority_lut[157] = 3'd7;
        priority_lut[158] = 3'd7;
        priority_lut[159] = 3'd7;
        priority_lut[160] = 3'd7;
        priority_lut[161] = 3'd7;
        priority_lut[162] = 3'd7;
        priority_lut[163] = 3'd7;
        priority_lut[164] = 3'd7;
        priority_lut[165] = 3'd7;
        priority_lut[166] = 3'd7;
        priority_lut[167] = 3'd7;
        priority_lut[168] = 3'd7;
        priority_lut[169] = 3'd7;
        priority_lut[170] = 3'd7;
        priority_lut[171] = 3'd7;
        priority_lut[172] = 3'd7;
        priority_lut[173] = 3'd7;
        priority_lut[174] = 3'd7;
        priority_lut[175] = 3'd7;
        priority_lut[176] = 3'd7;
        priority_lut[177] = 3'd7;
        priority_lut[178] = 3'd7;
        priority_lut[179] = 3'd7;
        priority_lut[180] = 3'd7;
        priority_lut[181] = 3'd7;
        priority_lut[182] = 3'd7;
        priority_lut[183] = 3'd7;
        priority_lut[184] = 3'd7;
        priority_lut[185] = 3'd7;
        priority_lut[186] = 3'd7;
        priority_lut[187] = 3'd7;
        priority_lut[188] = 3'd7;
        priority_lut[189] = 3'd7;
        priority_lut[190] = 3'd7;
        priority_lut[191] = 3'd7;
        priority_lut[192] = 3'd7;
        priority_lut[193] = 3'd7;
        priority_lut[194] = 3'd7;
        priority_lut[195] = 3'd7;
        priority_lut[196] = 3'd7;
        priority_lut[197] = 3'd7;
        priority_lut[198] = 3'd7;
        priority_lut[199] = 3'd7;
        priority_lut[200] = 3'd7;
        priority_lut[201] = 3'd7;
        priority_lut[202] = 3'd7;
        priority_lut[203] = 3'd7;
        priority_lut[204] = 3'd7;
        priority_lut[205] = 3'd7;
        priority_lut[206] = 3'd7;
        priority_lut[207] = 3'd7;
        priority_lut[208] = 3'd7;
        priority_lut[209] = 3'd7;
        priority_lut[210] = 3'd7;
        priority_lut[211] = 3'd7;
        priority_lut[212] = 3'd7;
        priority_lut[213] = 3'd7;
        priority_lut[214] = 3'd7;
        priority_lut[215] = 3'd7;
        priority_lut[216] = 3'd7;
        priority_lut[217] = 3'd7;
        priority_lut[218] = 3'd7;
        priority_lut[219] = 3'd7;
        priority_lut[220] = 3'd7;
        priority_lut[221] = 3'd7;
        priority_lut[222] = 3'd7;
        priority_lut[223] = 3'd7;
        priority_lut[224] = 3'd7;
        priority_lut[225] = 3'd7;
        priority_lut[226] = 3'd7;
        priority_lut[227] = 3'd7;
        priority_lut[228] = 3'd7;
        priority_lut[229] = 3'd7;
        priority_lut[230] = 3'd7;
        priority_lut[231] = 3'd7;
        priority_lut[232] = 3'd7;
        priority_lut[233] = 3'd7;
        priority_lut[234] = 3'd7;
        priority_lut[235] = 3'd7;
        priority_lut[236] = 3'd7;
        priority_lut[237] = 3'd7;
        priority_lut[238] = 3'd7;
        priority_lut[239] = 3'd7;
        priority_lut[240] = 3'd7;
        priority_lut[241] = 3'd7;
        priority_lut[242] = 3'd7;
        priority_lut[243] = 3'd7;
        priority_lut[244] = 3'd7;
        priority_lut[245] = 3'd7;
        priority_lut[246] = 3'd7;
        priority_lut[247] = 3'd7;
        priority_lut[248] = 3'd7;
        priority_lut[249] = 3'd7;
        priority_lut[250] = 3'd7;
        priority_lut[251] = 3'd7;
        priority_lut[252] = 3'd7;
        priority_lut[253] = 3'd7;
        priority_lut[254] = 3'd7;
        priority_lut[255] = 3'd7;
    end
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending[g] <= {INTS_PER_GUEST{1'b0}};
                virt_int_mask[g] <= {INTS_PER_GUEST{1'b1}};
                guest_int_id[g] <= 3'd0;
            end
            int_pending_guest <= {GUESTS{1'b0}};
            guest_switch_done <= 1'b0;
            current_state <= IDLE;
        end else begin
            // Process physical interrupts to virtual pending state
            for (g = 0; g < GUESTS; g = g + 1) begin
                virt_int_pending[g] <= virt_int_pending[g] | 
                    phys_int[g*INTS_PER_GUEST +: INTS_PER_GUEST];
                    
                // Check if any unmasked interrupts for this guest
                int_pending_guest[g] <= |(virt_int_pending[g] & ~virt_int_mask[g]);
                
                // Find highest pending interrupt using LUT
                if (|(virt_int_pending[g] & ~virt_int_mask[g])) begin
                    guest_int_id[g] <= priority_lut[virt_int_pending[g] & ~virt_int_mask[g]];
                end
            end
            
            // Guest switching state machine
            case (current_state)
                IDLE: begin
                    guest_switch_done <= 1'b0;
                    if (guest_switch_req)
                        current_state <= SAVE_CONTEXT;
                end
                
                SAVE_CONTEXT: begin
                    // Save virtual interrupt state for current guest
                    current_state <= SWITCH_PENDING;
                end
                
                SWITCH_PENDING: begin
                    // Handle guest switching
                    current_state <= RESTORE_CONTEXT;
                end
                
                RESTORE_CONTEXT: begin
                    // Restore virtual interrupt state for new guest
                    current_state <= SWITCH_DONE;
                end
                
                SWITCH_DONE: begin
                    guest_switch_done <= 1'b1;
                    current_state <= IDLE;
                end
                
                default: current_state <= IDLE;
            endcase
        end
    end
endmodule